import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v6.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = migrationV6.join('\n');
  });

  group('Recipe Migration V6', () {
    test('supports database version 6 or later', () {
      expect(
        AppConstants.databaseVersion,
        greaterThanOrEqualTo(6),
      );
    });

    test('adds audit columns', () {
      expect(
        sql,
        contains('ADD COLUMN created_at'),
      );

      expect(
        sql,
        contains('ADD COLUMN updated_at'),
      );

      expect(
        sql,
        contains('ADD COLUMN created_by'),
      );

      expect(
        sql,
        contains('ADD COLUMN updated_by'),
      );
    });

    test('adds synchronization columns', () {
      expect(
        sql,
        contains('ADD COLUMN sync_status'),
      );

      expect(
        sql,
        contains('ADD COLUMN server_version'),
      );

      expect(
        sql,
        contains('ADD COLUMN deleted_at'),
      );
    });

    test('supports all synchronization states', () {
      expect(sql, contains("'PENDING'"));
      expect(sql, contains("'SYNCING'"));
      expect(sql, contains("'SYNCED'"));
      expect(sql, contains("'ERROR'"));
    });

    test('creates synchronization index', () {
      expect(
        sql,
        contains('idx_recipe_master_sync'),
      );
    });

    test('creates active and deleted index', () {
      expect(
        sql,
        contains(
          'idx_recipe_master_active_deleted',
        ),
      );
    });

    test('does not modify released migrations', () {
      expect(
        sql,
        isNot(contains('DROP TABLE')),
      );

      expect(
        sql,
        isNot(
          contains('ALTER TABLE recipes'),
        ),
      );
    });
  });
}
