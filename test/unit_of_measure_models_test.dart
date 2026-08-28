import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/unit_conversion.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/domain/services/standard_units.dart';

void main() {
  final DateTime timestamp = DateTime.utc(2026, 8, 28);

  group('UnitOfMeasure', () {
    test('serializes controlled unit types', () {
      expect(
        unitTypeToStorage(UnitType.count),
        'COUNT',
      );
      expect(
        unitTypeToStorage(UnitType.weight),
        'WEIGHT',
      );
      expect(
        unitTypeToStorage(UnitType.volume),
        'VOLUME',
      );
      expect(
        unitTypeToStorage(UnitType.packaging),
        'PACKAGING',
      );
    });

    test('rejects unsupported unit type', () {
      expect(
        () => unitTypeFromStorage('TIME'),
        throwsFormatException,
      );
    });

    test('rejects self-referencing base unit', () {
      final UnitOfMeasure unit = UnitOfMeasure(
        id: 'UOM-KG',
        code: 'KG',
        name: 'Kilogram',
        unitType: UnitType.weight,
        baseUnitCode: 'KG',
        conversionFactor: 1,
        allowDecimal: true,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      expect(unit.validate, throwsFormatException);
    });

    test('maps to SQLite column names', () {
      final UnitOfMeasure unit = UnitOfMeasure(
        id: 'UOM-KG',
        code: 'KG',
        name: 'Kilogram',
        unitType: UnitType.weight,
        baseUnitCode: 'GRAM',
        conversionFactor: 1000,
        allowDecimal: true,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      final Map<String, Object?> map = unit.toSqlite();

      expect(map['unit_type'], 'WEIGHT');
      expect(map['base_unit_code'], 'GRAM');
      expect(map['conversion_factor'], 1000);
      expect(map['allow_decimal'], 1);
    });
  });

  group('Standard units', () {
    test('contains nine standard units', () {
      final units = StandardUnits.create(
        timestamp: timestamp,
      );

      expect(units.length, 9);
      expect(
        units.map((unit) => unit.code),
        containsAll(<String>[
          'PCS',
          'GRAM',
          'KG',
          'ML',
          'LITER',
          'PACK',
          'BOX',
          'BOTTLE',
          'CAN',
        ]),
      );
    });

    test('contains only universal physical conversions', () {
      final conversions = StandardUnits.universalConversions(
        timestamp: timestamp,
      );

      expect(conversions.length, 2);

      expect(
        conversions.any(
          (conversion) =>
              conversion.sourceUnitCode == 'KG' &&
              conversion.targetUnitCode == 'GRAM' &&
              conversion.conversionFactor == 1000,
        ),
        isTrue,
      );

      expect(
        conversions.any(
          (conversion) =>
              conversion.sourceUnitCode == 'LITER' &&
              conversion.targetUnitCode == 'ML' &&
              conversion.conversionFactor == 1000,
        ),
        isTrue,
      );

      expect(
        conversions.any(
          (conversion) =>
              conversion.sourceUnitCode == 'BOX' &&
              conversion.targetUnitCode == 'PCS',
        ),
        isFalse,
      );
    });

    test('converts kilograms to grams', () {
      final UnitConversion conversion = StandardUnits.universalConversions(
        timestamp: timestamp,
      ).first;

      expect(conversion.convert(2.5), 2500);
    });

    test('rejects negative conversion quantity', () {
      final UnitConversion conversion = StandardUnits.universalConversions(
        timestamp: timestamp,
      ).first;

      expect(
        () => conversion.convert(-1),
        throwsFormatException,
      );
    });
  });

  unitConversionSerializationTests();
}

void unitConversionSerializationTests() {
  final DateTime timestamp = DateTime.utc(2026, 8, 28);

  group('UnitConversion serialization', () {
    test('parses a SQLite conversion record', () {
      final UnitConversion conversion = UnitConversion.fromSqlite(
        <String, Object?>{
          'id': 'UOM-CONV-KG-GRAM',
          'source_unit_code': 'KG',
          'target_unit_code': 'GRAM',
          'conversion_factor': 1000.0,
          'conversion_scope': 'UNIVERSAL',
          'active': 1,
          'created_at': timestamp.toIso8601String(),
          'updated_at': timestamp.toIso8601String(),
          'sync_status': 'SYNCED',
          'server_version': 1,
        },
      );

      expect(conversion.sourceUnitCode, 'KG');
      expect(conversion.targetUnitCode, 'GRAM');
      expect(conversion.conversionFactor, 1000);
      expect(conversion.active, isTrue);
    });

    test('parses a Firebase conversion record', () {
      final UnitConversion conversion = UnitConversion.fromFirebase(
        'UOM-CONV-LITER-ML',
        <Object?, Object?>{
          'id': 'UOM-CONV-LITER-ML',
          'sourceUnitCode': 'LITER',
          'targetUnitCode': 'ML',
          'conversionFactor': 1000,
          'conversionScope': 'UNIVERSAL',
          'active': true,
          'createdAt': timestamp.toIso8601String(),
          'updatedAt': timestamp.toIso8601String(),
          'syncStatus': 'SYNCED',
          'serverVersion': 2,
        },
      );

      expect(conversion.sourceUnitCode, 'LITER');
      expect(conversion.targetUnitCode, 'ML');
      expect(conversion.serverVersion, 2);
    });

    test('maps conversion to Firebase fields', () {
      final UnitConversion conversion = UnitConversion(
        id: 'UOM-CONV-KG-GRAM',
        sourceUnitCode: 'kg',
        targetUnitCode: 'gram',
        conversionFactor: 1000,
        scope: ConversionScope.universal,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      final Map<String, Object?> map = conversion.toFirebase();

      expect(map['sourceUnitCode'], 'KG');
      expect(map['targetUnitCode'], 'GRAM');
      expect(map['conversionScope'], 'UNIVERSAL');
      expect(map['active'], isTrue);
    });

    test('rejects item-specific universal records', () {
      final UnitConversion conversion = UnitConversion(
        id: 'PRODUCT-BOX-PCS',
        sourceUnitCode: 'BOX',
        targetUnitCode: 'PCS',
        conversionFactor: 24,
        scope: ConversionScope.itemSpecific,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      expect(
        conversion.validate,
        throwsFormatException,
      );
    });

    test('copyWith preserves unchanged conversion values', () {
      final UnitConversion original = UnitConversion(
        id: 'UOM-CONV-KG-GRAM',
        sourceUnitCode: 'KG',
        targetUnitCode: 'GRAM',
        conversionFactor: 1000,
        scope: ConversionScope.universal,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      final UnitConversion updated = original.copyWith(
        active: false,
      );

      expect(updated.id, original.id);
      expect(updated.conversionFactor, 1000);
      expect(updated.active, isFalse);
    });
  });
}
