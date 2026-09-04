import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String database;
  late String constants;

  setUpAll(() {
    migration = File(
      'lib/data/local/migrations/'
      'migration_v8.dart',
    ).readAsStringSync();

    database = File(
      'lib/data/local/database.dart',
    ).readAsStringSync();

    constants = File(
      'lib/core/constants/app_constants.dart',
    ).readAsStringSync();
  });

  group('Product Sync Migration V8', () {
    test('increases database version to 8', () {
      expect(
        constants,
        contains(
          'databaseVersion = 8',
        ),
      );
    });

    test('adds Product sync status', () {
      expect(
        migration,
        contains(
          'ALTER TABLE products',
        ),
      );

      expect(
        migration,
        contains(
          'ADD COLUMN sync_status TEXT NOT NULL',
        ),
      );

      expect(
        migration,
        contains(
          "DEFAULT 'PENDING'",
        ),
      );

      for (final String status in <String>[
        'PENDING',
        'SYNCING',
        'SYNCED',
        'ERROR',
      ]) {
        expect(
          migration,
          contains("'$status'"),
        );
      }
    });

    test('adds Product server version', () {
      expect(
        migration,
        contains(
          'ADD COLUMN server_version '
          'INTEGER NOT NULL',
        ),
      );

      expect(
        migration,
        contains(
          'CHECK(server_version >= 0)',
        ),
      );
    });

    test('adds Product deletion tombstone', () {
      expect(
        migration,
        contains(
          'ADD COLUMN deleted_at TEXT',
        ),
      );
    });

    test('creates Product sync index', () {
      expect(
        migration,
        contains(
          'idx_products_sync',
        ),
      );

      expect(
        migration,
        contains(
          'ON products(sync_status)',
        ),
      );
    });

    test('creates Product active deletion index', () {
      expect(
        migration,
        contains(
          'idx_products_active_deleted',
        ),
      );

      expect(
        migration,
        contains(
          'ON products(active, deleted_at)',
        ),
      );
    });

    test('imports Migration V8', () {
      expect(
        database,
        contains(
          'migrations/migration_v8.dart',
        ),
      );
    });

    test('runs V8 during fresh creation', () {
      expect(
        database,
        contains(
          'if (version >= 8)',
        ),
      );

      expect(
        database,
        contains('migrationV8'),
      );
    });

    test('runs V8 during database upgrade', () {
      expect(
        database,
        contains(
          'oldVersion < 8 && '
          'newVersion >= 8',
        ),
      );
    });
  });
}
