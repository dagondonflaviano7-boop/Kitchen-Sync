import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v4.dart';

void main() {
  group('Migration V4 contract', () {
    test(
      'Migration V4 remains included in the current database version',
      () {
        expect(
          AppConstants.databaseVersion,
          greaterThanOrEqualTo(4),
        );
      },
    );

    test('adds Ingredient audit and synchronization columns', () {
      final String migration = migrationV4.join('\n');

      expect(migration, contains('ADD COLUMN notes TEXT'));
      expect(migration, contains('ADD COLUMN image_path TEXT'));
      expect(migration, contains('ADD COLUMN created_by TEXT'));
      expect(migration, contains('ADD COLUMN updated_by TEXT'));
      expect(migration, contains('ADD COLUMN sync_status TEXT'));
      expect(migration, contains('ADD COLUMN server_version INTEGER'));
      expect(migration, contains('ADD COLUMN deleted_at TEXT'));
    });

    test('adds Ingredient search and sync indexes', () {
      final String migration = migrationV4.join('\n');

      expect(
        migration,
        contains('idx_ingredients_name'),
      );
      expect(
        migration,
        contains('idx_ingredients_category'),
      );
      expect(
        migration,
        contains('idx_ingredients_supplier'),
      );
      expect(
        migration,
        contains('idx_ingredients_sync'),
      );
      expect(
        migration,
        contains('idx_ingredients_active_deleted'),
      );
    });

    test('does not create a duplicate Ingredients table', () {
      final String migration = migrationV4.join('\n');

      expect(
        migration,
        isNot(contains('CREATE TABLE ingredients')),
      );
    });
  });
}
