import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:sqflite/sqflite.dart';

class RecipeDao {
  const RecipeDao();

  Future<void> insertRecipe(
    DatabaseExecutor database,
    Recipe recipe,
  ) async {
    recipe.validate();

    final Map<String, Object?> header = recipe.toSqlite();

    final Batch batch = database.batch();

    batch.insert(
      'recipe_master',
      header,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    for (final RecipeIngredient ingredient in recipe.ingredients) {
      ingredient.validate();

      batch.insert(
        'recipe_ingredients',
        ingredient.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }

    await batch.commit(
      noResult: true,
      continueOnError: false,
    );
  }

  Future<void> updateRecipe(
    DatabaseExecutor database,
    Recipe recipe,
  ) async {
    recipe.validate();

    final List<Map<String, Object?>> existingRows = await database.query(
      'recipe_master',
      columns: const <String>['id'],
      where: 'id = ?',
      whereArgs: <Object?>[
        recipe.id.trim(),
      ],
      limit: 1,
    );

    if (existingRows.isEmpty) {
      throw StateError(
        'The Recipe record was not found.',
      );
    }

    final Batch batch = database.batch();

    batch.update(
      'recipe_master',
      recipe.toSqlite(),
      where: 'id = ?',
      whereArgs: <Object?>[
        recipe.id.trim(),
      ],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    batch.delete(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: <Object?>[
        recipe.id.trim(),
      ],
    );

    for (final RecipeIngredient ingredient in recipe.ingredients) {
      ingredient.validate();

      batch.insert(
        'recipe_ingredients',
        ingredient.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }

    await batch.commit(
      noResult: true,
      continueOnError: false,
    );
  }

  Future<void> deleteRecipe(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    await softDelete(
      database,
      recipeId,
      updatedBy: 'SYSTEM',
    );
  }

  Future<void> softDelete(
    DatabaseExecutor database,
    String recipeId, {
    required String updatedBy,
    DateTime? deletedAt,
  }) async {
    final String normalizedId = recipeId.trim();

    final String normalizedUserId = updatedBy.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    if (normalizedUserId.isEmpty) {
      throw const FormatException(
        'Updated By is required.',
      );
    }

    final String timestamp =
        (deletedAt ?? DateTime.now()).toUtc().toIso8601String();

    final int updated = await database.update(
      'recipe_master',
      <String, Object?>{
        'active': 0,
        'updated_at': timestamp,
        'updated_by': normalizedUserId,
        'sync_status': 'PENDING',
        'deleted_at': timestamp,
      },
      where: '''
        id = ?
        AND deleted_at IS NULL
      ''',
      whereArgs: <Object?>[
        normalizedId,
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Recipe record was not found '
        'or was already deleted.',
      );
    }
  }

  Future<Recipe?> findByIdIncludingDeleted(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    final String normalizedId = recipeId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final List<Map<String, Object?>> headerRows = await database.query(
      'recipe_master',
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
      limit: 1,
    );

    if (headerRows.isEmpty) {
      return null;
    }

    final List<RecipeIngredient> ingredients = await _getIngredientsByRecipeId(
      database,
      normalizedId,
    );

    return Recipe.fromSqlite(
      headerRows.first,
    ).copyWith(
      ingredients: ingredients,
    );
  }

  Future<bool> recipeCodeExists(
    DatabaseExecutor database,
    String recipeCode, {
    String? excludingId,
  }) async {
    final String normalizedCode = recipeCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw const FormatException(
        'Recipe Code is required.',
      );
    }

    String where = '''
      recipe_code = ?
      AND deleted_at IS NULL
    ''';

    final List<Object?> arguments = <Object?>[
      normalizedCode,
    ];

    final String excludedId = excludingId?.trim() ?? '';

    if (excludedId.isNotEmpty) {
      where = '$where AND id != ?';
      arguments.add(excludedId);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'recipe_master',
      columns: const <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<Recipe?> getRecipeById(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    final String normalizedId = recipeId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final List<Map<String, Object?>> headerRows = await database.query(
      'recipe_master',
      where: '''
        id = ?
        AND deleted_at IS NULL
      ''',
      whereArgs: <Object?>[
        normalizedId,
      ],
      limit: 1,
    );

    if (headerRows.isEmpty) {
      return null;
    }

    final List<RecipeIngredient> ingredients = await _getIngredientsByRecipeId(
      database,
      normalizedId,
    );

    return Recipe.fromSqlite(
      headerRows.first,
    ).copyWith(
      ingredients: ingredients,
    );
  }

  Future<List<Recipe>> getRecipes(
    DatabaseExecutor database,
  ) async {
    final List<Map<String, Object?>> headerRows = await database.query(
      'recipe_master',
      where: 'deleted_at IS NULL',
      orderBy: '''
        recipe_name COLLATE NOCASE,
        recipe_code
      ''',
    );

    final List<Recipe> recipes = <Recipe>[];

    for (final Map<String, Object?> header in headerRows) {
      final Recipe recipe = Recipe.fromSqlite(header);

      final List<RecipeIngredient> ingredients =
          await _getIngredientsByRecipeId(
        database,
        recipe.id,
      );

      recipes.add(
        recipe.copyWith(
          ingredients: ingredients,
        ),
      );
    }

    return List<Recipe>.unmodifiable(
      recipes,
    );
  }

  Future<List<Recipe>> findPending(
    DatabaseExecutor database, {
    int limit = 100,
  }) async {
    if (limit < 1) {
      throw const FormatException(
        'Pending synchronization limit '
        'must be greater than zero.',
      );
    }

    final List<Map<String, Object?>> headerRows = await database.query(
      'recipe_master',
      where: 'sync_status IN (?, ?)',
      whereArgs: const <Object?>[
        'PENDING',
        'ERROR',
      ],
      orderBy: 'updated_at, id',
      limit: limit,
    );

    final List<Recipe> recipes = <Recipe>[];

    for (final Map<String, Object?> header in headerRows) {
      final Recipe recipe = Recipe.fromSqlite(header);

      final List<RecipeIngredient> ingredients =
          await _getIngredientsByRecipeId(
        database,
        recipe.id,
      );

      recipes.add(
        recipe.copyWith(
          ingredients: ingredients,
        ),
      );
    }

    return List<Recipe>.unmodifiable(
      recipes,
    );
  }

  Future<void> markSyncing(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    await _updateSyncStatus(
      database,
      recipeId,
      MasterSyncStatus.syncing,
    );
  }

  Future<void> markSynced(
    DatabaseExecutor database,
    String recipeId, {
    required int serverVersion,
  }) async {
    if (serverVersion < 0) {
      throw const FormatException(
        'Server version must be zero or greater.',
      );
    }

    final String normalizedId = recipeId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final int updated = await database.update(
      'recipe_master',
      <String, Object?>{
        'sync_status': 'SYNCED',
        'server_version': serverVersion,
      },
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Recipe record was not found.',
      );
    }
  }

  Future<void> markSyncError(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    await _updateSyncStatus(
      database,
      recipeId,
      MasterSyncStatus.error,
    );
  }

  Future<void> _updateSyncStatus(
    DatabaseExecutor database,
    String recipeId,
    MasterSyncStatus status,
  ) async {
    final String normalizedId = recipeId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final int updated = await database.update(
      'recipe_master',
      <String, Object?>{
        'sync_status': masterSyncStatusToStorage(status),
      },
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Recipe record was not found.',
      );
    }
  }

  Future<void> upsertRemote(
    Database database,
    Recipe recipe,
  ) async {
    recipe.validate();

    final Recipe synchronized = recipe.copyWith(
      syncStatus: MasterSyncStatus.synced,
    );

    await database.transaction(
      (Transaction transaction) async {
        await transaction.insert(
          'recipe_master',
          synchronized.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await transaction.delete(
          'recipe_ingredients',
          where: 'recipe_id = ?',
          whereArgs: <Object?>[
            synchronized.id,
          ],
        );

        for (final RecipeIngredient ingredient in synchronized.ingredients) {
          final RecipeIngredient normalizedLine = ingredient.copyWith(
            recipeId: synchronized.id,
          );

          normalizedLine.validate();

          await transaction.insert(
            'recipe_ingredients',
            normalizedLine.toSqlite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
    );
  }

  Future<List<RecipeIngredient>> _getIngredientsByRecipeId(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: <Object?>[
        recipeId.trim(),
      ],
      orderBy: '''
        ingredient_name COLLATE NOCASE,
        id
      ''',
    );

    return rows
        .map(
          RecipeIngredient.fromSqlite,
        )
        .toList(growable: false);
  }
}
