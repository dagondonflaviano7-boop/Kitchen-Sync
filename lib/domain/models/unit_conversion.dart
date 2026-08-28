import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

enum ConversionScope {
  universal,
  itemSpecific,
}

String conversionScopeToStorage(
  ConversionScope scope,
) {
  return switch (scope) {
    ConversionScope.universal => 'UNIVERSAL',
    ConversionScope.itemSpecific => 'ITEM_SPECIFIC',
  };
}

ConversionScope conversionScopeFromStorage(
  String value,
) {
  return switch (value.trim().toUpperCase()) {
    'UNIVERSAL' => ConversionScope.universal,
    'ITEM_SPECIFIC' => ConversionScope.itemSpecific,
    _ => throw FormatException(
        'Unsupported conversion scope: $value',
      ),
  };
}

class UnitConversion {
  final String id;
  final String sourceUnitCode;
  final String targetUnitCode;
  final double conversionFactor;
  final ConversionScope scope;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MasterSyncStatus syncStatus;
  final int serverVersion;

  const UnitConversion({
    required this.id,
    required this.sourceUnitCode,
    required this.targetUnitCode,
    required this.conversionFactor,
    required this.scope,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = MasterSyncStatus.pending,
    this.serverVersion = 0,
  });

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException(
        'Conversion ID is required.',
      );
    }

    if (sourceUnitCode.trim().isEmpty || targetUnitCode.trim().isEmpty) {
      throw const FormatException(
        'Source and target unit codes are required.',
      );
    }

    if (sourceUnitCode.trim().toUpperCase() ==
        targetUnitCode.trim().toUpperCase()) {
      throw const FormatException(
        'Source and target units must be different.',
      );
    }

    if (conversionFactor <= 0) {
      throw const FormatException(
        'Conversion factor must be greater than zero.',
      );
    }

    if (scope == ConversionScope.itemSpecific) {
      throw const FormatException(
        'Item-specific conversions must be stored '
        'with the product packaging record.',
      );
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id,
      'source_unit_code': sourceUnitCode.trim().toUpperCase(),
      'target_unit_code': targetUnitCode.trim().toUpperCase(),
      'conversion_factor': conversionFactor,
      'conversion_scope': conversionScopeToStorage(scope),
      'active': active ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'sync_status': masterSyncStatusToStorage(syncStatus),
      'server_version': serverVersion,
    };
  }

  double convert(double quantity) {
    if (quantity < 0) {
      throw const FormatException(
        'Quantity cannot be negative.',
      );
    }

    return quantity * conversionFactor;
  }
}
