import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String database;
  late String constants;

  setUpAll(() {
    migration = File(
      'lib/data/local/migrations/'
      'migration_v7.dart',
    ).readAsStringSync();

    database = File(
      'lib/data/local/database.dart',
    ).readAsStringSync();

    constants = File(
      'lib/core/constants/app_constants.dart',
    ).readAsStringSync();
  });

  group('Product Recipe Migration V7', () {
    test('increases database version to 7', () {
      expect(
        constants,
        contains(
          'databaseVersion = 7',
        ),
      );
    });

    test('adds nullable Recipe ID to Products', () {
      expect(
        migration,
        contains(
          'ALTER TABLE products',
        ),
      );

      expect(
        migration,
        contains(
          'ADD COLUMN recipe_id TEXT',
        ),
      );

      expect(
        migration,
        isNot(
          contains(
            'recipe_id TEXT NOT NULL',
          ),
        ),
      );
    });

    test('creates Product Recipe index', () {
      expect(
        migration,
        contains(
          'CREATE INDEX IF NOT EXISTS',
        ),
      );

      expect(
        migration,
        contains(
          'idx_products_recipe_id',
        ),
      );

      expect(
        migration,
        contains(
          'ON products(recipe_id)',
        ),
      );
    });

    test('imports Migration V7', () {
      expect(
        database,
        contains(
          "migrations/migration_v7.dart",
        ),
      );
    });

    test('runs V7 during fresh creation', () {
      expect(
        database,
        contains(
          'if (version >= 7)',
        ),
      );

      expect(
        database,
        contains(
          'migrationV7',
        ),
      );
    });

    test('runs V7 during database upgrade', () {
      expect(
        database,
        contains(
          'oldVersion < 7 && '
          'newVersion >= 7',
        ),
      );
    });
  });
}
