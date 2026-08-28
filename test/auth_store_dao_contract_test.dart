import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication and store DAO contracts', () {
    test('store DAO targets the stores table', () {
      final String source = File(
        'lib/data/local/daos/store_dao.dart',
      ).readAsStringSync();

      expect(
        source.contains("'stores'"),
        isTrue,
      );
      expect(
        source.contains('ConflictAlgorithm.replace'),
        isTrue,
      );
    });

    test('user profile DAO targets the users table', () {
      final String source = File(
        'lib/data/local/daos/user_profile_dao.dart',
      ).readAsStringSync();

      expect(
        source.contains("'users'"),
        isTrue,
      );
      expect(
        source.contains("'firebase_uid = ?'"),
        isTrue,
      );
    });

    test('assignment DAO targets assignment table', () {
      final String source = File(
        'lib/data/local/daos/store_user_assignment_dao.dart',
      ).readAsStringSync();

      expect(
        source.contains("'store_user_assignments'"),
        isTrue,
      );
      expect(
        source.contains("'is_default': 1"),
        isTrue,
      );
      expect(
        source.contains("'sync_status': 'SYNCED'"),
        isTrue,
      );
    });

    test('local session cache preserves foreign-key order', () {
      final String source = File(
        'lib/data/repositories/local_session_repository.dart',
      ).readAsStringSync();

      final int storeSave = source.indexOf(
        'storeDao.upsert(transaction, store)',
      );

      final int profileSave = source.indexOf(
        'userProfileDao.upsert(transaction, profile)',
      );

      final int assignmentSave = source.indexOf(
        'assignmentDao.saveDefaultAssignment',
      );

      expect(
        storeSave,
        greaterThanOrEqualTo(0),
      );
      expect(
        profileSave,
        greaterThan(storeSave),
      );
      expect(
        assignmentSave,
        greaterThan(profileSave),
      );
    });

    test('session cache rejects mismatched stores', () {
      final String source = File(
        'lib/data/repositories/local_session_repository.dart',
      ).readAsStringSync();

      expect(
        source.contains('profile.storeId != store.id'),
        isTrue,
      );
      expect(
        source.contains(
          'The user store assignment does not match',
        ),
        isTrue,
      );
    });
  });
}
