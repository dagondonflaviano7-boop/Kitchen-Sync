import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:sqflite/sqflite.dart';

class IngredientDao {
  const IngredientDao();

  Future<void> upsert(
    DatabaseExecutor database,
    Ingredient ingredient,
  ) async {
    ingredient.validate();

    await database.insert(
      'ingredients',
      ingredient.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Ingredient?> findById(
    DatabaseExecutor database,
    String ingredientId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[
        ingredientId.trim(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Ingredient.fromSqlite(rows.first);
  }

  Future<Ingredient?> findByIdIncludingDeleted(
    DatabaseExecutor database,
    String ingredientId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: <Object?>[
        ingredientId.trim(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Ingredient.fromSqlite(rows.first);
  }

  Future<Ingredient?> findBySku(
    DatabaseExecutor database,
    String ingredientSku,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      where: '''
        ingredient_sku = ?
        AND deleted_at IS NULL
      ''',
      whereArgs: <Object?>[
        ingredientSku.trim().toUpperCase(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Ingredient.fromSqlite(rows.first);
  }

  Future<List<Ingredient>> findAll(
    DatabaseExecutor database, {
    bool includeInactive = true,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      where: includeInactive
          ? 'deleted_at IS NULL'
          : '''
            active = ?
            AND deleted_at IS NULL
          ''',
      whereArgs: includeInactive ? null : const <Object?>[1],
      orderBy: '''
        ingredient_name COLLATE NOCASE,
        ingredient_sku
      ''',
    );

    return rows.map(Ingredient.fromSqlite).toList(growable: false);
  }

  Future<List<Ingredient>> findAllIncludingDeleted(
    DatabaseExecutor database,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      orderBy: 'updated_at, id',
    );

    return rows.map(Ingredient.fromSqlite).toList(growable: false);
  }

  Future<List<Ingredient>> search(
    DatabaseExecutor database,
    String query, {
    bool includeInactive = true,
    IngredientCategory? category,
    String? supplierId,
  }) async {
    final String searchText = query.trim();

    final List<String> conditions = <String>[
      'deleted_at IS NULL',
    ];

    final List<Object?> arguments = <Object?>[];

    if (!includeInactive) {
      conditions.add('active = ?');
      arguments.add(1);
    }

    if (category != null) {
      conditions.add('category = ?');
      arguments.add(
        ingredientCategoryToStorage(category),
      );
    }

    final String normalizedSupplierId = supplierId?.trim() ?? '';

    if (normalizedSupplierId.isNotEmpty) {
      conditions.add('supplier_id = ?');
      arguments.add(normalizedSupplierId);
    }

    if (searchText.isNotEmpty) {
      conditions.add(
        '''
        (
          ingredient_sku LIKE ?
          OR ingredient_name LIKE ?
          OR category LIKE ?
          OR supplier_name LIKE ?
          OR unit_of_measure LIKE ?
          OR purchase_unit LIKE ?
        )
        ''',
      );

      final String pattern = '%$searchText%';

      arguments.addAll(
        <Object?>[
          pattern,
          pattern,
          pattern,
          pattern,
          pattern,
          pattern,
        ],
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      where: conditions.join(' AND '),
      whereArgs: arguments,
      orderBy: '''
        ingredient_name COLLATE NOCASE,
        ingredient_sku
      ''',
    );

    return rows.map(Ingredient.fromSqlite).toList(growable: false);
  }

  Future<bool> skuExists(
    DatabaseExecutor database,
    String ingredientSku, {
    String? excludingId,
  }) async {
    String where = '''
      ingredient_sku = ?
      AND deleted_at IS NULL
    ''';

    final List<Object?> arguments = <Object?>[
      ingredientSku.trim().toUpperCase(),
    ];

    final String excludedId = excludingId?.trim() ?? '';

    if (excludedId.isNotEmpty) {
      where = '$where AND id != ?';
      arguments.add(excludedId);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      columns: const <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String ingredientId,
    bool active, {
    required String updatedBy,
  }) async {
    final String userId = updatedBy.trim();

    if (userId.isEmpty) {
      throw const FormatException(
        'Updated By is required.',
      );
    }

    final int updated = await database.update(
      'ingredients',
      <String, Object?>{
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': userId,
        'sync_status': 'PENDING',
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[
        ingredientId.trim(),
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Ingredient record was not found.',
      );
    }
  }

  Future<void> softDelete(
    DatabaseExecutor database,
    String ingredientId, {
    required DateTime deletedAt,
    required String updatedBy,
  }) async {
    final String userId = updatedBy.trim();

    if (userId.isEmpty) {
      throw const FormatException(
        'Updated By is required.',
      );
    }

    final String timestamp = deletedAt.toUtc().toIso8601String();

    final int updated = await database.update(
      'ingredients',
      <String, Object?>{
        'active': 0,
        'deleted_at': timestamp,
        'updated_at': timestamp,
        'updated_by': userId,
        'sync_status': 'PENDING',
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[
        ingredientId.trim(),
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Ingredient record was not found '
        'or was already deleted.',
      );
    }
  }

  Future<bool> isReferenced(
    DatabaseExecutor database,
    String ingredientId,
  ) async {
    final String id = ingredientId.trim();

    final bool recipeReference = await _referenceExists(
      database,
      table: 'recipe_items',
      where: 'ingredient_id = ?',
      arguments: <Object?>[id],
    );

    if (recipeReference) {
      return true;
    }

    final bool inventoryReference = await _referenceExists(
      database,
      table: 'ingredient_inventory',
      where: 'ingredient_id = ?',
      arguments: <Object?>[id],
    );

    if (inventoryReference) {
      return true;
    }

    final bool movementReference = await _referenceExists(
      database,
      table: 'ingredient_movements',
      where: 'item_id = ?',
      arguments: <Object?>[id],
    );

    if (movementReference) {
      return true;
    }

    final bool receivingReference = await _referenceExists(
      database,
      table: 'receiving_items',
      where: '''
        item_id = ?
        AND item_type = ?
      ''',
      arguments: <Object?>[
        id,
        'INGREDIENT',
      ],
    );

    if (receivingReference) {
      return true;
    }

    final bool adjustmentReference = await _referenceExists(
      database,
      table: 'adjustment_items',
      where: '''
        item_id = ?
        AND item_type = ?
      ''',
      arguments: <Object?>[
        id,
        'INGREDIENT',
      ],
    );

    return adjustmentReference;
  }

  Future<bool> _referenceExists(
    DatabaseExecutor database, {
    required String table,
    required String where,
    required List<Object?> arguments,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      table,
      columns: const <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<List<Ingredient>> findPending(
    DatabaseExecutor database, {
    int limit = 100,
  }) async {
    if (limit < 1) {
      throw const FormatException(
        'Pending synchronization limit '
        'must be greater than zero.',
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'ingredients',
      where: 'sync_status IN (?, ?)',
      whereArgs: const <Object?>[
        'PENDING',
        'ERROR',
      ],
      orderBy: 'updated_at, id',
      limit: limit,
    );

    return rows.map(Ingredient.fromSqlite).toList(growable: false);
  }

  Future<void> markSyncing(
    DatabaseExecutor database,
    String ingredientId,
  ) async {
    await _updateSyncStatus(
      database,
      ingredientId,
      MasterSyncStatus.syncing,
    );
  }

  Future<void> markSynced(
    DatabaseExecutor database,
    String ingredientId, {
    required int serverVersion,
  }) async {
    if (serverVersion < 0) {
      throw const FormatException(
        'Server version must be zero or greater.',
      );
    }

    final int updated = await database.update(
      'ingredients',
      <String, Object?>{
        'sync_status': 'SYNCED',
        'server_version': serverVersion,
      },
      where: 'id = ?',
      whereArgs: <Object?>[
        ingredientId.trim(),
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Ingredient record was not found.',
      );
    }
  }

  Future<void> markSyncError(
    DatabaseExecutor database,
    String ingredientId,
  ) async {
    await _updateSyncStatus(
      database,
      ingredientId,
      MasterSyncStatus.error,
    );
  }

  Future<void> _updateSyncStatus(
    DatabaseExecutor database,
    String ingredientId,
    MasterSyncStatus status,
  ) async {
    final int updated = await database.update(
      'ingredients',
      <String, Object?>{
        'sync_status': masterSyncStatusToStorage(status),
      },
      where: 'id = ?',
      whereArgs: <Object?>[
        ingredientId.trim(),
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Ingredient record was not found.',
      );
    }
  }

  Future<void> upsertRemote(
    DatabaseExecutor database,
    Ingredient ingredient,
  ) async {
    ingredient.validate();

    final Ingredient synchronized = ingredient.copyWith(
      syncStatus: MasterSyncStatus.synced,
    );

    await database.insert(
      'ingredients',
      synchronized.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
