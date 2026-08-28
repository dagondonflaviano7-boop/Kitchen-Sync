class Store {
  final String id;
  final String storeCode;
  final String storeName;
  final String address;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Store({
    required this.id,
    required this.storeCode,
    required this.storeName,
    required this.address,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory Store.fromFirebase(
    String key,
    Map<Object?, Object?> data,
  ) {
    final Map<String, dynamic> map = _stringMap(data);

    final String id = _requiredString(
      map['storeId'] ?? key,
      'storeId',
    );
    final String storeCode = _requiredString(
      map['storeCode'],
      'storeCode',
    );
    final String storeName = _requiredString(
      map['storeName'],
      'storeName',
    );

    return Store(
      id: id,
      storeCode: storeCode,
      storeName: storeName,
      address: _optionalString(map['address']),
      active: _requiredBool(map['active'], 'active'),
      createdAt: _optionalDateTime(map['createdAt']),
      updatedAt: _optionalDateTime(map['updatedAt']),
    );
  }

  factory Store.fromSqlite(Map<String, Object?> map) {
    return Store(
      id: _requiredString(map['id'], 'id'),
      storeCode: _requiredString(
        map['store_code'],
        'store_code',
      ),
      storeName: _requiredString(
        map['store_name'],
        'store_name',
      ),
      address: _optionalString(map['address']),
      active: _sqliteBool(map['active'], 'active'),
      createdAt: _optionalDateTime(map['created_at']),
      updatedAt: _optionalDateTime(map['updated_at']),
    );
  }

  Map<String, Object?> toSqlite() {
    return {
      'id': id,
      'store_code': storeCode,
      'store_name': storeName,
      'address': address,
      'active': active ? 1 : 0,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toFirebase() {
    return {
      'storeId': id,
      'storeCode': storeCode,
      'storeName': storeName,
      'address': address,
      'active': active,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  Store copyWith({
    String? id,
    String? storeCode,
    String? storeName,
    String? address,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      storeCode: storeCode ?? this.storeCode,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Map<String, dynamic> _stringMap(
    Map<Object?, Object?> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key.toString(), value),
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

  static String _optionalString(Object? value) {
    return value?.toString().trim() ?? '';
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

  static DateTime? _optionalDateTime(Object? value) {
    final String date = value?.toString().trim() ?? '';

    if (date.isEmpty) {
      return null;
    }

    return DateTime.tryParse(date);
  }
}
