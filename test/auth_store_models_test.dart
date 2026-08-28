import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/core/permissions/role.dart';
import 'package:kitchen_sync/domain/models/store.dart';
import 'package:kitchen_sync/domain/models/user_profile.dart';

void main() {
  group('Role serialization', () {
    test('serializes every supported role', () {
      expect(roleToStorage(UserRole.cashier), 'CASHIER');
      expect(
        roleToStorage(UserRole.inventoryUser),
        'INVENTORY_USER',
      );
      expect(roleToStorage(UserRole.manager), 'MANAGER');
      expect(
        roleToStorage(UserRole.supervisor),
        'SUPERVISOR',
      );
      expect(roleToStorage(UserRole.admin), 'ADMIN');
    });

    test('rejects an unsupported role', () {
      expect(
        () => roleFromStorage('OWNER'),
        throwsFormatException,
      );
    });
  });

  group('UserProfile model', () {
    test('parses Firebase administrator profile', () {
      final UserProfile profile = UserProfile.fromFirebase(
        'uid-001',
        {
          'userId': 'uid-001',
          'name': 'ADMIN',
          'email': 'admin@example.com',
          'role': 'ADMIN',
          'storeId': 'STORE001',
          'active': true,
        },
      );

      expect(profile.id, 'uid-001');
      expect(profile.role, UserRole.admin);
      expect(profile.storeId, 'STORE001');
      expect(profile.active, isTrue);
      expect(profile.can(Permission.manageUsers), isTrue);
    });

    test('rejects a missing store assignment', () {
      expect(
        () => UserProfile.fromFirebase(
          'uid-001',
          {
            'userId': 'uid-001',
            'name': 'ADMIN',
            'email': 'admin@example.com',
            'role': 'ADMIN',
            'storeId': '',
            'active': true,
          },
        ),
        throwsFormatException,
      );
    });

    test('converts to SQLite column names', () {
      const UserProfile profile = UserProfile(
        id: 'uid-001',
        name: 'ADMIN',
        email: 'admin@example.com',
        role: UserRole.admin,
        storeId: 'STORE001',
        active: true,
      );

      final Map<String, Object?> map = profile.toSqlite();

      expect(map['firebase_uid'], 'uid-001');
      expect(map['store_id'], 'STORE001');
      expect(map['role'], 'ADMIN');
      expect(map['active'], 1);
    });
  });

  group('Store model', () {
    test('parses Firebase store', () {
      final Store store = Store.fromFirebase(
        'STORE001',
        {
          'storeId': 'STORE001',
          'storeCode': 'STORE001',
          'storeName': 'Kitchen Sync Main Store',
          'address': '',
          'active': true,
        },
      );

      expect(store.id, 'STORE001');
      expect(store.storeCode, 'STORE001');
      expect(store.active, isTrue);
    });

    test('rejects missing store name', () {
      expect(
        () => Store.fromFirebase(
          'STORE001',
          {
            'storeId': 'STORE001',
            'storeCode': 'STORE001',
            'storeName': '',
            'active': true,
          },
        ),
        throwsFormatException,
      );
    });

    test('converts to SQLite column names', () {
      const Store store = Store(
        id: 'STORE001',
        storeCode: 'STORE001',
        storeName: 'Kitchen Sync Main Store',
        address: '',
        active: true,
      );

      final Map<String, Object?> map = store.toSqlite();

      expect(map['id'], 'STORE001');
      expect(map['store_code'], 'STORE001');
      expect(map['store_name'], 'Kitchen Sync Main Store');
      expect(map['active'], 1);
    });
  });
}
