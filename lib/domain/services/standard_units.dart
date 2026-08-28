import 'package:kitchen_sync/domain/models/unit_conversion.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

class StandardUnits {
  StandardUnits._();

  static List<UnitOfMeasure> create({
    required DateTime timestamp,
  }) {
    return <UnitOfMeasure>[
      _unit(
        code: 'PCS',
        name: 'Pieces',
        type: UnitType.count,
        allowDecimal: false,
        timestamp: timestamp,
      ),
      _unit(
        code: 'GRAM',
        name: 'Gram',
        type: UnitType.weight,
        allowDecimal: true,
        timestamp: timestamp,
      ),
      _unit(
        code: 'KG',
        name: 'Kilogram',
        type: UnitType.weight,
        baseUnitCode: 'GRAM',
        conversionFactor: 1000,
        allowDecimal: true,
        timestamp: timestamp,
      ),
      _unit(
        code: 'ML',
        name: 'Milliliter',
        type: UnitType.volume,
        allowDecimal: true,
        timestamp: timestamp,
      ),
      _unit(
        code: 'LITER',
        name: 'Liter',
        type: UnitType.volume,
        baseUnitCode: 'ML',
        conversionFactor: 1000,
        allowDecimal: true,
        timestamp: timestamp,
      ),
      _unit(
        code: 'PACK',
        name: 'Pack',
        type: UnitType.packaging,
        allowDecimal: false,
        timestamp: timestamp,
      ),
      _unit(
        code: 'BOX',
        name: 'Box',
        type: UnitType.packaging,
        allowDecimal: false,
        timestamp: timestamp,
      ),
      _unit(
        code: 'BOTTLE',
        name: 'Bottle',
        type: UnitType.packaging,
        allowDecimal: false,
        timestamp: timestamp,
      ),
      _unit(
        code: 'CAN',
        name: 'Can',
        type: UnitType.packaging,
        allowDecimal: false,
        timestamp: timestamp,
      ),
    ];
  }

  static List<UnitConversion> universalConversions({
    required DateTime timestamp,
  }) {
    return <UnitConversion>[
      UnitConversion(
        id: 'UOM-CONV-KG-GRAM',
        sourceUnitCode: 'KG',
        targetUnitCode: 'GRAM',
        conversionFactor: 1000,
        scope: ConversionScope.universal,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      UnitConversion(
        id: 'UOM-CONV-LITER-ML',
        sourceUnitCode: 'LITER',
        targetUnitCode: 'ML',
        conversionFactor: 1000,
        scope: ConversionScope.universal,
        active: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ];
  }

  static UnitOfMeasure _unit({
    required String code,
    required String name,
    required UnitType type,
    required bool allowDecimal,
    required DateTime timestamp,
    String? baseUnitCode,
    double conversionFactor = 1,
  }) {
    return UnitOfMeasure(
      id: 'UOM-$code',
      code: code,
      name: name,
      unitType: type,
      baseUnitCode: baseUnitCode,
      conversionFactor: conversionFactor,
      allowDecimal: allowDecimal,
      active: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}
