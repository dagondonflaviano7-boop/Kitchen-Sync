import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v2.dart';

void main() {
  group('Migration V2 contract', () {
    final String migrationSql = migrationV2.join(' ');

    test('creates store user assignments', () {
      expect(
        migrationSql.contains(
          'CREATE TABLE IF NOT EXISTS store_user_assignments',
        ),
        isTrue,
      );
    });

    test('creates master data synchronization state', () {
      expect(
        migrationSql.contains(
          'CREATE TABLE IF NOT EXISTS master_data_sync_state',
        ),
        isTrue,
      );
    });

    test('creates master data conflict tracking', () {
      expect(
        migrationSql.contains(
          'CREATE TABLE IF NOT EXISTS master_data_conflicts',
        ),
        isTrue,
      );
    });

    test('uses controlled conflict statuses', () {
      expect(
        migrationSql.contains('RESOLVED_LOCAL'),
        isTrue,
      );
      expect(
        migrationSql.contains('RESOLVED_REMOTE'),
        isTrue,
      );
      expect(
        migrationSql.contains('MERGED'),
        isTrue,
      );
    });
  });
}
