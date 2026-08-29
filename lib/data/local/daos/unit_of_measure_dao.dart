import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:sqflite/sqflite.dart';

class UnitOfMeasureDao {
  const UnitOfMeasureDao();

  Future<void> upsert(
    DatabaseExecutor database,
    UnitOfMeasure unit,
  ) async {
    await database.insert(
      'units_of_measure',
      unit.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(
    DatabaseExecutor database,
    Iterable<UnitOfMeasure> units,
  ) async {
    for (final UnitOfMeasure unit in units) {
      await upsert(database, unit);
    }
  }

  Future<UnitOfMeasure?> findById(
    DatabaseExecutor database,
    String id,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UnitOfMeasure.fromSqlite(rows.first);
  }

  Future<UnitOfMeasure?> findByIdIncludingDeleted(
    DatabaseExecutor database,
    String unitId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      where: 'id = ?',
      whereArgs: <Object?>[unitId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UnitOfMeasure.fromSqlite(rows.first);
  }

  Future<UnitOfMeasure?> findByCode(
    DatabaseExecutor database,
    String code,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      where: 'code = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[
        code.trim().toUpperCase(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UnitOfMeasure.fromSqlite(rows.first);
  }

  Future<List<UnitOfMeasure>> findAll(
    DatabaseExecutor database, {
    bool includeInactive = true,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      where: includeInactive
          ? 'deleted_at IS NULL'
          : 'active = ? AND deleted_at IS NULL',
      whereArgs: includeInactive ? null : <Object?>[1],
      orderBy: 'unit_type, name COLLATE NOCASE',
    );

    return rows.map(UnitOfMeasure.fromSqlite).toList(growable: false);
  }

  Future<List<UnitOfMeasure>> search(
    DatabaseExecutor database,
    String query, {
    bool includeInactive = true,
  }) async {
    final String searchText = query.trim();

    if (searchText.isEmpty) {
      return findAll(
        database,
        includeInactive: includeInactive,
      );
    }

    final List<Object?> arguments = <Object?>[
      '%$searchText%',
      '%$searchText%',
    ];

    String where = '(code LIKE ? OR name LIKE ?) AND deleted_at IS NULL';

    if (!includeInactive) {
      where = '$where AND active = ?';
      arguments.add(1);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      where: where,
      whereArgs: arguments,
      orderBy: 'unit_type, name COLLATE NOCASE',
    );

    return rows.map(UnitOfMeasure.fromSqlite).toList(growable: false);
  }

  Future<bool> codeExists(
    DatabaseExecutor database,
    String code, {
    String? excludingId,
  }) async {
    final String normalizedCode = code.trim().toUpperCase();

    String where = 'code = ?';
    final List<Object?> arguments = <Object?>[
      normalizedCode,
    ];

    if (excludingId != null && excludingId.trim().isNotEmpty) {
      where = '$where AND id != ?';
      arguments.add(excludingId);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      columns: <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String id,
    bool active,
  ) async {
    await database.update(
      'units_of_measure',
      <String, Object?>{
        'active': active ? 1 : 0,
        'sync_status': 'PENDING',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> softDelete(
    DatabaseExecutor database,
    String unitId, {
    required DateTime deletedAt,
  }) async {
    final String timestamp = deletedAt.toUtc().toIso8601String();

    final int updated = await database.update(
      'units_of_measure',
      <String, Object?>{
        'active': 0,
        'deleted_at': timestamp,
        'updated_at': timestamp,
        'sync_status': 'PENDING',
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[unitId],
    );

    if (updated == 0) {
      throw StateError(
        'The unit record was not found or was already deleted.',
      );
    }
  }

  Future<bool> isReferenced(
    DatabaseExecutor database,
    String unitCode,
  ) async {
    final String code = unitCode.trim().toUpperCase();

    final List<Map<String, Object?>> checks = <Map<String, Object?>>[
      <String, Object?>{
        'table': 'ingredients',
        'where': 'unit_of_measure = ? OR purchase_unit = ?',
        'arguments': <Object?>[code, code],
      },
      <String, Object?>{
        'table': 'recipe_items',
        'where': 'unit = ?',
        'arguments': <Object?>[code],
      },
      <String, Object?>{
        'table': 'unit_conversions',
        'where': 'source_unit_code = ? '
            'OR target_unit_code = ?',
        'arguments': <Object?>[code, code],
      },
      <String, Object?>{
        'table': 'product_packaging_conversions',
        'where': 'source_unit_code = ? '
            'OR target_unit_code = ?',
        'arguments': <Object?>[code, code],
      },
    ];

    for (final Map<String, Object?> check in checks) {
      final List<Map<String, Object?>> rows = await database.query(
        check['table']! as String,
        columns: const <String>['id'],
        where: check['where']! as String,
        whereArgs: check['arguments']! as List<Object?>,
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Future<List<UnitOfMeasure>> findPending(
    DatabaseExecutor database, {
    int limit = 100,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      where: 'sync_status IN (?, ?)',
      whereArgs: const <Object?>[
        'PENDING',
        'ERROR',
      ],
      orderBy: 'updated_at, id',
      limit: limit,
    );

    return rows.map(UnitOfMeasure.fromSqlite).toList(growable: false);
  }

  Future<List<UnitOfMeasure>> findAllIncludingDeleted(
    DatabaseExecutor database,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'units_of_measure',
      orderBy: 'updated_at, id',
    );

    return rows.map(UnitOfMeasure.fromSqlite).toList(growable: false);
  }

  Future<void> markSyncing(
    DatabaseExecutor database,
    String unitId,
  ) async {
    final int updated = await database.update(
      'units_of_measure',
      <String, Object?>{
        'sync_status': 'SYNCING',
      },
      where: 'id = ?',
      whereArgs: <Object?>[unitId],
    );

    if (updated == 0) {
      throw StateError(
        'The Unit record was not found.',
      );
    }
  }

  Future<void> markSynced(
    DatabaseExecutor database,
    String unitId, {
    required int serverVersion,
  }) async {
    final int updated = await database.update(
      'units_of_measure',
      <String, Object?>{
        'sync_status': 'SYNCED',
        'server_version': serverVersion,
      },
      where: 'id = ?',
      whereArgs: <Object?>[unitId],
    );

    if (updated == 0) {
      throw StateError(
        'The Unit record was not found.',
      );
    }
  }

  Future<void> markSyncError(
    DatabaseExecutor database,
    String unitId,
  ) async {
    final int updated = await database.update(
      'units_of_measure',
      <String, Object?>{
        'sync_status': 'ERROR',
      },
      where: 'id = ?',
      whereArgs: <Object?>[unitId],
    );

    if (updated == 0) {
      throw StateError(
        'The Unit record was not found.',
      );
    }
  }

  Future<void> upsertRemote(
    DatabaseExecutor database,
    UnitOfMeasure unit,
  ) async {
    final Map<String, Object?> values = Map<String, Object?>.from(
      unit.toSqlite(),
    );

    values['sync_status'] = 'SYNCED';

    await database.insert(
      'units_of_measure',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
