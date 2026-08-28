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
      where: 'id = ?',
      whereArgs: <Object?>[id],
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
      where: 'code = ?',
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
      where: includeInactive ? null : 'active = ?',
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

    String where = '(code LIKE ? OR name LIKE ?)';

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
}
