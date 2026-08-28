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

  factory UnitConversion.fromSqlite(
    Map<String, Object?> map,
  ) {
    final UnitConversion conversion = UnitConversion(
      id: _requiredString(map['id'], 'id'),
      sourceUnitCode: _requiredCode(
        map['source_unit_code'],
        'source_unit_code',
      ),
      targetUnitCode: _requiredCode(
        map['target_unit_code'],
        'target_unit_code',
      ),
      conversionFactor: _positiveNumber(
        map['conversion_factor'],
        'conversion_factor',
      ),
      scope: conversionScopeFromStorage(
        _requiredString(
          map['conversion_scope'],
          'conversion_scope',
        ),
      ),
      active: _sqliteBool(
        map['active'],
        'active',
      ),
      createdAt: _requiredDateTime(
        map['created_at'],
        'created_at',
      ),
      updatedAt: _requiredDateTime(
        map['updated_at'],
        'updated_at',
      ),
      syncStatus: masterSyncStatusFromStorage(
        _requiredString(
          map['sync_status'],
          'sync_status',
        ),
      ),
      serverVersion: _nonNegativeInteger(
        map['server_version'],
        'server_version',
      ),
    );

    conversion.validate();
    return conversion;
  }

  factory UnitConversion.fromFirebase(
    String key,
    Map<Object?, Object?> data,
  ) {
    final Map<String, dynamic> map = data.map(
      (key, value) => MapEntry(
        key.toString(),
        value,
      ),
    );

    final UnitConversion conversion = UnitConversion(
      id: _requiredString(
        map['id'] ?? key,
        'id',
      ),
      sourceUnitCode: _requiredCode(
        map['sourceUnitCode'],
        'sourceUnitCode',
      ),
      targetUnitCode: _requiredCode(
        map['targetUnitCode'],
        'targetUnitCode',
      ),
      conversionFactor: _positiveNumber(
        map['conversionFactor'],
        'conversionFactor',
      ),
      scope: conversionScopeFromStorage(
        map['conversionScope']?.toString() ?? 'UNIVERSAL',
      ),
      active: _requiredBool(
        map['active'],
        'active',
      ),
      createdAt: _requiredDateTime(
        map['createdAt'],
        'createdAt',
      ),
      updatedAt: _requiredDateTime(
        map['updatedAt'],
        'updatedAt',
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['syncStatus']?.toString() ?? 'SYNCED',
      ),
      serverVersion: _nonNegativeInteger(
        map['serverVersion'] ?? 0,
        'serverVersion',
      ),
    );

    conversion.validate();
    return conversion;
  }

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

    if (serverVersion < 0) {
      throw const FormatException(
        'Server version cannot be negative.',
      );
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
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

  Map<String, Object?> toFirebase() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'sourceUnitCode': sourceUnitCode.trim().toUpperCase(),
      'targetUnitCode': targetUnitCode.trim().toUpperCase(),
      'conversionFactor': conversionFactor,
      'conversionScope': conversionScopeToStorage(scope),
      'active': active,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'syncStatus': masterSyncStatusToStorage(syncStatus),
      'serverVersion': serverVersion,
    };
  }

  UnitConversion copyWith({
    String? id,
    String? sourceUnitCode,
    String? targetUnitCode,
    double? conversionFactor,
    ConversionScope? scope,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    MasterSyncStatus? syncStatus,
    int? serverVersion,
  }) {
    return UnitConversion(
      id: id ?? this.id,
      sourceUnitCode: sourceUnitCode ?? this.sourceUnitCode,
      targetUnitCode: targetUnitCode ?? this.targetUnitCode,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      scope: scope ?? this.scope,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
    );
  }

  double convert(double quantity) {
    validate();

    if (quantity < 0) {
      throw const FormatException(
        'Quantity cannot be negative.',
      );
    }

    return quantity * conversionFactor;
  }

  static String _requiredString(
    Object? value,
    String field,
  ) {
    final String result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      throw FormatException('$field is required.');
    }

    return result;
  }

  static String _requiredCode(
    Object? value,
    String field,
  ) {
    return _requiredString(
      value,
      field,
    ).toUpperCase();
  }

  static double _positiveNumber(
    Object? value,
    String field,
  ) {
    final double? result = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    if (result == null || result <= 0) {
      throw FormatException(
        '$field must be greater than zero.',
      );
    }

    return result;
  }

  static int _nonNegativeInteger(
    Object? value,
    String field,
  ) {
    final int? result =
        value is int ? value : int.tryParse(value?.toString() ?? '');

    if (result == null || result < 0) {
      throw FormatException(
        '$field must be zero or greater.',
      );
    }

    return result;
  }

  static bool _requiredBool(
    Object? value,
    String field,
  ) {
    if (value is bool) {
      return value;
    }

    throw FormatException(
      '$field must be a boolean.',
    );
  }

  static bool _sqliteBool(
    Object? value,
    String field,
  ) {
    if (value == 1 || value == true) {
      return true;
    }

    if (value == 0 || value == false) {
      return false;
    }

    throw FormatException(
      '$field must be 0 or 1.',
    );
  }

  static DateTime _requiredDateTime(
    Object? value,
    String field,
  ) {
    final DateTime? result = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (result == null) {
      throw FormatException(
        '$field must be a valid date.',
      );
    }

    return result;
  }
}
