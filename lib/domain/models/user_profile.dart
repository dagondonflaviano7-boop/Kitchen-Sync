import 'package:kitchen_sync/core/permissions/role.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String storeId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.storeId,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirebase(
    String uid,
    Map<Object?, Object?> data,
  ) {
    final Map<String, dynamic> map = _stringMap(data);

    final String id = _requiredString(
      map['userId'] ?? uid,
      'userId',
    );

    return UserProfile(
      id: id,
      name: _requiredString(map['name'], 'name'),
      email: _requiredEmail(map['email']),
      role: roleFromStorage(
        _requiredString(map['role'], 'role'),
      ),
      storeId: _requiredString(
        map['storeId'],
        'storeId',
      ),
      active: _requiredBool(map['active'], 'active'),
      createdAt: _optionalDateTime(map['createdAt']),
      updatedAt: _optionalDateTime(map['updatedAt']),
    );
  }

  factory UserProfile.fromSqlite(
    Map<String, Object?> map,
  ) {
    return UserProfile(
      id: _requiredString(map['id'], 'id'),
      name: _requiredString(map['name'], 'name'),
      email: _requiredEmail(map['email']),
      role: roleFromStorage(
        _requiredString(map['role'], 'role'),
      ),
      storeId: _requiredString(
        map['store_id'],
        'store_id',
      ),
      active: _sqliteBool(map['active'], 'active'),
      createdAt: _optionalDateTime(map['created_at']),
      updatedAt: _optionalDateTime(map['updated_at']),
    );
  }

  Map<String, Object?> toSqlite() {
    return {
      'id': id,
      'firebase_uid': id,
      'name': name,
      'email': email,
      'role': roleToStorage(role),
      'store_id': storeId,
      'active': active ? 1 : 0,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toFirebase() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'role': roleToStorage(role),
      'storeId': storeId,
      'active': active,
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? storeId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool can(Permission permission) {
    return hasPermission(role, permission);
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

  static String _requiredEmail(Object? value) {
    final String email = _requiredString(value, 'email');

    if (!email.contains('@')) {
      throw const FormatException(
        'A valid email address is required.',
      );
    }

    return email;
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
