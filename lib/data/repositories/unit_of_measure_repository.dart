import 'package:kitchen_sync/data/local/daos/unit_conversion_dao.dart';
import 'package:kitchen_sync/data/local/daos/unit_of_measure_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/unit_conversion.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/domain/services/standard_units.dart';
import 'package:sqflite/sqflite.dart';

class UnitOfMeasureRepository {
  final UnitOfMeasureDao unitDao;
  final UnitConversionDao conversionDao;

  const UnitOfMeasureRepository({
    this.unitDao = const UnitOfMeasureDao(),
    this.conversionDao = const UnitConversionDao(),
  });

  Future<void> seedStandardUnits() async {
    final Database database = await AppDatabase.instance.database;

    final DateTime now = DateTime.now().toUtc();

    await database.transaction(
      (Transaction transaction) async {
        final List<UnitOfMeasure> units = StandardUnits.create(
          timestamp: now,
        );

        final List<UnitConversion> conversions =
            StandardUnits.universalConversions(
          timestamp: now,
        );

        for (final UnitOfMeasure unit in units) {
          final UnitOfMeasure? existing = await unitDao.findByCode(
            transaction,
            unit.code,
          );

          if (existing == null) {
            await unitDao.upsert(
              transaction,
              unit,
            );
          }
        }

        for (final UnitConversion conversion in conversions) {
          final UnitConversion? existing = await conversionDao.findById(
            transaction,
            conversion.id,
          );

          if (existing == null) {
            await conversionDao.upsert(
              transaction,
              conversion,
            );
          }
        }
      },
    );
  }

  Future<List<UnitOfMeasure>> getUnits({
    bool includeInactive = true,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return unitDao.findAll(
      database,
      includeInactive: includeInactive,
    );
  }

  Future<List<UnitOfMeasure>> searchUnits(
    String query, {
    bool includeInactive = true,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return unitDao.search(
      database,
      query,
      includeInactive: includeInactive,
    );
  }

  Future<UnitOfMeasure?> findUnitByCode(
    String code,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return unitDao.findByCode(
      database,
      code,
    );
  }

  Future<void> saveUnit(
    UnitOfMeasure unit,
  ) async {
    unit.validate();

    final Database database = await AppDatabase.instance.database;

    final bool duplicate = await unitDao.codeExists(
      database,
      unit.code,
      excludingId: unit.id,
    );

    if (duplicate) {
      throw StateError(
        'A unit with code ${unit.code.toUpperCase()} '
        'already exists.',
      );
    }

    await unitDao.upsert(
      database,
      unit,
    );
  }

  Future<void> setUnitActive(
    String unitId,
    bool active,
  ) async {
    final Database database = await AppDatabase.instance.database;

    await unitDao.setActive(
      database,
      unitId,
      active,
    );
  }

  Future<double> convert({
    required double quantity,
    required String sourceUnitCode,
    required String targetUnitCode,
  }) async {
    if (quantity < 0) {
      throw const FormatException(
        'Quantity cannot be negative.',
      );
    }

    final String source = sourceUnitCode.trim().toUpperCase();
    final String target = targetUnitCode.trim().toUpperCase();

    if (source == target) {
      return quantity;
    }

    final Database database = await AppDatabase.instance.database;

    final UnitConversion? direct = await conversionDao.findActiveConversion(
      database,
      sourceUnitCode: source,
      targetUnitCode: target,
    );

    if (direct != null) {
      return direct.convert(quantity);
    }

    final UnitConversion? reverse = await conversionDao.findActiveConversion(
      database,
      sourceUnitCode: target,
      targetUnitCode: source,
    );

    if (reverse != null) {
      return quantity / reverse.conversionFactor;
    }

    throw StateError(
      'No active universal conversion exists '
      'from $source to $target.',
    );
  }
}
