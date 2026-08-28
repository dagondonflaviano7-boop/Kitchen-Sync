enum UnitType {
  count,
  weight,
  volume,
  packaging,
}

enum MasterSyncStatus {
  pending,
  syncing,
  synced,
  error,
}

String unitTypeToStorage(UnitType type) {
  return switch (type) {
    UnitType.count => 'COUNT',
    UnitType.weight => 'WEIGHT',
    UnitType.volume => 'VOLUME',
    UnitType.packaging => 'PACKAGING',
  };
}

UnitType unitTypeFromStorage(String value) {
  return switch (value.trim().toUpperCase()) {
    'COUNT' => UnitType.count,
    'WEIGHT' => UnitType.weight,
    'VOLUME' => UnitType.volume,
    'PACKAGING' => UnitType.packaging,
    _ => throw FormatException(
        'Unsupported unit type: $value',
      ),
  };
}

String masterSyncStatusToStorage(
  MasterSyncStatus status,
) {
  return switch (status) {
    MasterSyncStatus.pending => 'PENDING',
    MasterSyncStatus.syncing => 'SYNCING',
    MasterSyncStatus.synced => 'SYNCED',
    MasterSyncStatus.error => 'ERROR',
  };
}

MasterSyncStatus masterSyncStatusFromStorage(
  String value,
) {
  return switch (value.trim().toUpperCase()) {
    'PENDING' => MasterSyncStatus.pending,
    'SYNCING' => MasterSyncStatus.syncing,
    'SYNCED' => MasterSyncStatus.synced,
    'ERROR' => MasterSyncStatus.error,
    _ => throw FormatException(
        'Unsupported synchronization status: $value',
      ),
  };
}

class UnitOfMeasure {
  final String id;
  final String code;
  final String name;
  final UnitType unitType;
  final String? baseUnitCode;
  final double conversionFactor;
  final bool allowDecimal;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MasterSyncStatus syncStatus;
  final int serverVersion;
  final DateTime? deletedAt;

  const UnitOfMeasure({
    required this.id,
    required this.code,
    required this.name,
    required this.unitType,
    required this.baseUnitCode,
    required this.conversionFactor,
    required this.allowDecimal,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = MasterSyncStatus.pending,
    this.serverVersion = 0,
    this.deletedAt,
  });

  factory UnitOfMeasure.fromSqlite(
    Map<String, Object?> map,
  ) {
    return UnitOfMeasure(
      id: _requiredString(map['id'], 'id'),
      code: _normalizedCode(map['code']),
      name: _requiredString(map['name'], 'name'),
      unitType: unitTypeFromStorage(
        _requiredString(map['unit_type'], 'unit_type'),
      ),
      baseUnitCode: _optionalCode(map['base_unit_code']),
      conversionFactor: _positiveNumber(
        map['conversion_factor'],
        'conversion_factor',
      ),
      allowDecimal: _sqliteBool(
        map['allow_decimal'],
        'allow_decimal',
      ),
      active: _sqliteBool(map['active'], 'active'),
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
      deletedAt: _optionalDateTime(map['deleted_at']),
    );
  }

  factory UnitOfMeasure.fromFirebase(
    String key,
    Map<Object?, Object?> data,
  ) {
    final Map<String, dynamic> map = data.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return UnitOfMeasure(
      id: _requiredString(
        map['id'] ?? key,
        'id',
      ),
      code: _normalizedCode(map['code']),
      name: _requiredString(map['name'], 'name'),
      unitType: unitTypeFromStorage(
        _requiredString(map['unitType'], 'unitType'),
      ),
      baseUnitCode: _optionalCode(map['baseUnitCode']),
      conversionFactor: _positiveNumber(
        map['conversionFactor'] ?? 1,
        'conversionFactor',
      ),
      allowDecimal: _requiredBool(
        map['allowDecimal'],
        'allowDecimal',
      ),
      active: _requiredBool(map['active'], 'active'),
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
      deletedAt: _optionalDateTime(map['deletedAt']),
    );
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException('Unit ID is required.');
    }

    if (code.trim().isEmpty) {
      throw const FormatException('Unit code is required.');
    }

    if (name.trim().isEmpty) {
      throw const FormatException('Unit name is required.');
    }

    if (conversionFactor <= 0) {
      throw const FormatException(
        'Conversion factor must be greater than zero.',
      );
    }

    if (baseUnitCode != null &&
        baseUnitCode!.trim().toUpperCase() == code.trim().toUpperCase()) {
      throw const FormatException(
        'A unit cannot use itself as its base unit.',
      );
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id,
      'code': code.trim().toUpperCase(),
      'name': name.trim(),
      'unit_type': unitTypeToStorage(unitType),
      'base_unit_code': baseUnitCode?.trim().toUpperCase(),
      'conversion_factor': conversionFactor,
      'allow_decimal': allowDecimal ? 1 : 0,
      'active': active ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'sync_status': masterSyncStatusToStorage(syncStatus),
      'server_version': serverVersion,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toFirebase() {
    validate();

    return <String, Object?>{
      'id': id,
      'code': code.trim().toUpperCase(),
      'name': name.trim(),
      'unitType': unitTypeToStorage(unitType),
      'baseUnitCode': baseUnitCode?.trim().toUpperCase(),
      'conversionFactor': conversionFactor,
      'allowDecimal': allowDecimal,
      'active': active,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'syncStatus': masterSyncStatusToStorage(syncStatus),
      'serverVersion': serverVersion,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  UnitOfMeasure copyWith({
    String? id,
    String? code,
    String? name,
    UnitType? unitType,
    String? baseUnitCode,
    double? conversionFactor,
    bool? allowDecimal,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    MasterSyncStatus? syncStatus,
    int? serverVersion,
    DateTime? deletedAt,
  }) {
    return UnitOfMeasure(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      unitType: unitType ?? this.unitType,
      baseUnitCode: baseUnitCode ?? this.baseUnitCode,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      allowDecimal: allowDecimal ?? this.allowDecimal,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
    );
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

  static String _normalizedCode(Object? value) {
    return _requiredString(value, 'code').toUpperCase();
  }

  static String? _optionalCode(Object? value) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : result.toUpperCase();
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

    throw FormatException('$field must be a boolean.');
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

    throw FormatException('$field must be 0 or 1.');
  }

  static DateTime _requiredDateTime(
    Object? value,
    String field,
  ) {
    final DateTime? result = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (result == null) {
      throw FormatException('$field must be a valid date.');
    }

    return result;
  }

  static DateTime? _optionalDateTime(Object? value) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : DateTime.tryParse(result);
  }
}
