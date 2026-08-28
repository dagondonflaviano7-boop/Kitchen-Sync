import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

class Supplier {
  final String id;
  final String supplierCode;
  final String supplierName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;
  final String? paymentTerms;
  final int leadTimeDays;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final MasterSyncStatus syncStatus;
  final int serverVersion;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.supplierCode,
    required this.supplierName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.taxId,
    required this.paymentTerms,
    required this.leadTimeDays,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.syncStatus = MasterSyncStatus.pending,
    this.serverVersion = 0,
    this.deletedAt,
  });

  factory Supplier.fromSqlite(
    Map<String, Object?> map,
  ) {
    final Supplier supplier = Supplier(
      id: _requiredString(
        map['id'],
        'id',
      ),
      supplierCode: _requiredCode(
        map['supplier_code'],
        'supplier_code',
      ),
      supplierName: _requiredString(
        map['supplier_name'],
        'supplier_name',
      ),
      contactPerson: _optionalString(
        map['contact_person'],
      ),
      phone: _optionalString(
        map['phone'],
      ),
      email: _optionalString(
        map['email'],
      ),
      address: _optionalString(
        map['address'],
      ),
      taxId: _optionalString(
        map['tax_id'],
      ),
      paymentTerms: _optionalString(
        map['payment_terms'],
      ),
      leadTimeDays: _nonNegativeInteger(
        map['lead_time_days'] ?? 0,
        'lead_time_days',
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
      createdBy: _optionalString(
        map['created_by'],
      ),
      updatedBy: _optionalString(
        map['updated_by'],
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['sync_status']?.toString() ?? 'PENDING',
      ),
      serverVersion: _nonNegativeInteger(
        map['server_version'] ?? 0,
        'server_version',
      ),
      deletedAt: _optionalDateTime(
        map['deleted_at'],
      ),
    );

    supplier.validate();
    return supplier;
  }

  factory Supplier.fromFirebase(
    String key,
    Map<Object?, Object?> data,
  ) {
    final Map<String, dynamic> map = data.map(
      (key, value) => MapEntry(
        key.toString(),
        value,
      ),
    );

    final Supplier supplier = Supplier(
      id: _requiredString(
        map['id'] ?? key,
        'id',
      ),
      supplierCode: _requiredCode(
        map['supplierCode'],
        'supplierCode',
      ),
      supplierName: _requiredString(
        map['supplierName'],
        'supplierName',
      ),
      contactPerson: _optionalString(
        map['contactPerson'],
      ),
      phone: _optionalString(
        map['phone'],
      ),
      email: _optionalString(
        map['email'],
      ),
      address: _optionalString(
        map['address'],
      ),
      taxId: _optionalString(
        map['taxId'],
      ),
      paymentTerms: _optionalString(
        map['paymentTerms'],
      ),
      leadTimeDays: _nonNegativeInteger(
        map['leadTimeDays'] ?? 0,
        'leadTimeDays',
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
      createdBy: _optionalString(
        map['createdBy'],
      ),
      updatedBy: _optionalString(
        map['updatedBy'],
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['syncStatus']?.toString() ?? 'SYNCED',
      ),
      serverVersion: _nonNegativeInteger(
        map['serverVersion'] ?? 0,
        'serverVersion',
      ),
      deletedAt: _optionalDateTime(
        map['deletedAt'],
      ),
    );

    supplier.validate();
    return supplier;
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException(
        'Supplier ID is required.',
      );
    }

    final String normalizedCode = supplierCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw const FormatException(
        'Supplier code is required.',
      );
    }

    if (normalizedCode.length > 30) {
      throw const FormatException(
        'Supplier code must not exceed 30 characters.',
      );
    }

    if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(
      normalizedCode,
    )) {
      throw const FormatException(
        'Supplier code may contain only letters, '
        'numbers, and underscores.',
      );
    }

    final String normalizedName = supplierName.trim();

    if (normalizedName.isEmpty) {
      throw const FormatException(
        'Supplier name is required.',
      );
    }

    if (normalizedName.length > 120) {
      throw const FormatException(
        'Supplier name must not exceed 120 characters.',
      );
    }

    if (leadTimeDays < 0) {
      throw const FormatException(
        'Lead time cannot be negative.',
      );
    }

    if (serverVersion < 0) {
      throw const FormatException(
        'Server version cannot be negative.',
      );
    }

    final String? normalizedEmail = _optionalString(email);

    if (normalizedEmail != null && !_looksLikeEmail(normalizedEmail)) {
      throw const FormatException(
        'Enter a valid email address.',
      );
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'supplier_code': supplierCode.trim().toUpperCase(),
      'supplier_name': supplierName.trim(),
      'contact_person': _optionalString(contactPerson),
      'phone': _optionalString(phone),
      'email': _optionalString(email),
      'address': _optionalString(address),
      'tax_id': _optionalString(taxId),
      'payment_terms': _optionalString(paymentTerms),
      'lead_time_days': leadTimeDays,
      'active': active ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'created_by': _optionalString(createdBy),
      'updated_by': _optionalString(updatedBy),
      'sync_status': masterSyncStatusToStorage(syncStatus),
      'server_version': serverVersion,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toFirebase() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'supplierCode': supplierCode.trim().toUpperCase(),
      'supplierName': supplierName.trim(),
      'contactPerson': _optionalString(contactPerson),
      'phone': _optionalString(phone),
      'email': _optionalString(email),
      'address': _optionalString(address),
      'taxId': _optionalString(taxId),
      'paymentTerms': _optionalString(paymentTerms),
      'leadTimeDays': leadTimeDays,
      'active': active,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'createdBy': _optionalString(createdBy),
      'updatedBy': _optionalString(updatedBy),
      'syncStatus': masterSyncStatusToStorage(syncStatus),
      'serverVersion': serverVersion,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  Supplier copyWith({
    String? id,
    String? supplierCode,
    String? supplierName,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? paymentTerms,
    int? leadTimeDays,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    MasterSyncStatus? syncStatus,
    int? serverVersion,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
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
      throw FormatException(
        '$field is required.',
      );
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

  static String? _optionalString(Object? value) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : result;
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

  static DateTime? _optionalDateTime(
    Object? value,
  ) {
    final String result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      return null;
    }

    return DateTime.tryParse(result);
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(value);
  }
}
