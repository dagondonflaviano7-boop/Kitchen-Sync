import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String database;
  late String constants;

  setUpAll(() {
    migration = File(
      'lib/data/local/migrations/'
      'migration_v10.dart',
    ).readAsStringSync();

    database = File(
      'lib/data/local/database.dart',
    ).readAsStringSync();

    constants = File(
      'lib/core/constants/app_constants.dart',
    ).readAsStringSync();
  });

  group('Ingredient Movement Recipe Lineage Migration V10', () {
    test('increases database version to 10', () {
      expect(
        constants,
        contains(
          'databaseVersion = 10',
        ),
      );
    });

    test('defines Migration V10 statements', () {
      expect(
        migration,
        contains(
          'const List<String> migrationV10',
        ),
      );
    });

    test('adds Recipe ID', () {
      expect(
        migration,
        contains(
          'ALTER TABLE ingredient_movements',
        ),
      );

      expect(
        migration,
        contains(
          'ADD COLUMN recipe_id TEXT',
        ),
      );
    });

    test('adds Recipe Ingredient ID', () {
      expect(
        migration,
        contains(
          'ADD COLUMN recipe_ingredient_id TEXT',
        ),
      );
    });

    test('creates Recipe lookup index', () {
      expect(
        migration,
        contains(
          'idx_ingredient_movements_recipe',
        ),
      );

      expect(
        migration,
        contains(
          'ON ingredient_movements(recipe_id)',
        ),
      );
    });

    test('creates Recipe line lookup index', () {
      expect(
        migration,
        contains(
          'idx_ingredient_movements_recipe_line',
        ),
      );

      expect(
        migration,
        contains(
          'ON ingredient_movements(recipe_ingredient_id)',
        ),
      );
    });

    test('imports Migration V10', () {
      expect(
        database,
        contains(
          'migrations/migration_v10.dart',
        ),
      );
    });

    test('runs V10 during fresh creation', () {
      expect(
        database,
        contains(
          'if (version >= 10)',
        ),
      );

      expect(
        database,
        contains(
          'migrationV10',
        ),
      );
    });

    test('runs V10 during database upgrade', () {
      expect(
        database,
        contains(
          'oldVersion < 10 && newVersion >= 10',
        ),
      );
    });

    test('does not update Ingredient balances', () {
      expect(
        migration,
        isNot(
          contains(
            'UPDATE ingredient_inventory',
          ),
        ),
      );
    });

    test('does not drop movement tables', () {
      expect(
        migration.toUpperCase(),
        isNot(
          contains(
            'DROP TABLE',
          ),
        ),
      );
    });
  });
}
