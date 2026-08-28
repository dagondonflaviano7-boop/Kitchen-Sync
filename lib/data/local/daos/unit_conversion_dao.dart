import 'package:kitchen_sync/domain/models/unit_conversion.dart';
import 'package:sqflite/sqflite.dart';

class UnitConversionDao {
  const UnitConversionDao();

  Future<void> upsert(
    DatabaseExecutor database,
    UnitConversion conversion,
  ) async {
    await database.insert(
      'unit_conversions',
      conversion.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(
    DatabaseExecutor database,
    Iterable<UnitConversion> conversions,
  ) async {
    for (final UnitConversion conversion in conversions) {
      await upsert(database, conversion);
    }
  }

  Future<UnitConversion?> findById(
    DatabaseExecutor database,
    String id,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'unit_conversions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UnitConversion.fromSqlite(rows.first);
  }

  Future<UnitConversion?> findActiveConversion(
    DatabaseExecutor database, {
    required String sourceUnitCode,
    required String targetUnitCode,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'unit_conversions',
      where: 'source_unit_code = ? '
          'AND target_unit_code = ? '
          'AND conversion_scope = ? '
          'AND active = ?',
      whereArgs: <Object?>[
        sourceUnitCode.trim().toUpperCase(),
        targetUnitCode.trim().toUpperCase(),
        'UNIVERSAL',
        1,
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UnitConversion.fromSqlite(rows.first);
  }

  Future<List<UnitConversion>> findAll(
    DatabaseExecutor database, {
    bool includeInactive = true,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'unit_conversions',
      where: includeInactive ? null : 'active = ?',
      whereArgs: includeInactive ? null : <Object?>[1],
      orderBy: 'source_unit_code, target_unit_code',
    );

    return rows.map(UnitConversion.fromSqlite).toList(growable: false);
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String id,
    bool active,
  ) async {
    await database.update(
      'unit_conversions',
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
