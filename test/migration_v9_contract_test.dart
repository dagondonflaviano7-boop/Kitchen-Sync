import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String database;
  late String constants;

  setUpAll(() {
    migration = File(
      'lib/data/local/migrations/'
      'migration_v9.dart',
    ).readAsStringSync();

    database = File(
      'lib/data/local/database.dart',
    ).readAsStringSync();

    constants = File(
      'lib/core/constants/app_constants.dart',
    ).readAsStringSync();
  });

  group('Movement Audit Migration V9', () {
    test('increases database version to 9', () {
      expect(
        constants,
        contains(
          'databaseVersion = 9',
        ),
      );
    });

    test('defines Migration V9 statements', () {
      expect(
        migration,
        contains(
          'const List<String> migrationV9',
        ),
      );
    });

    test('imports Migration V9', () {
      expect(
        database,
        contains(
          'migrations/migration_v9.dart',
        ),
      );
    });

    test('runs V9 during fresh creation', () {
      expect(
        database,
        contains(
          'if (version >= 9)',
        ),
      );

      expect(
        RegExp(
          r'if\s*\(\s*version\s*>=\s*9\s*\)'
          r'\s*\{[\s\S]*?migrationV9[\s\S]*?\}',
        ).hasMatch(database),
        isTrue,
      );
    });

    test('runs V9 during database upgrade', () {
      expect(
        RegExp(
          r'if\s*\(\s*oldVersion\s*<\s*9'
          r'\s*&&\s*newVersion\s*>=\s*9\s*\)'
          r'\s*\{[\s\S]*?migrationV9[\s\S]*?\}',
        ).hasMatch(database),
        isTrue,
      );
    });

    group('Product movement audit metadata', () {
      test('adds Product movement idempotency key', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'inventory_movements',
            column: 'idempotency_key',
          ),
          isTrue,
        );
      });

      test('adds Product movement Sale ID', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'inventory_movements',
            column: 'source_sale_id',
          ),
          isTrue,
        );
      });

      test('adds Product movement Sale Item ID', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'inventory_movements',
            column: 'source_sale_item_id',
          ),
          isTrue,
        );
      });

      test('adds Product movement reversal reference', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'inventory_movements',
            column: 'reversal_of_movement_id',
          ),
          isTrue,
        );
      });

      test('adds Product movement unit cost snapshot', () {
        expect(
          RegExp(
            r'ALTER\s+TABLE\s+inventory_movements'
            r'[\s\S]*?ADD\s+COLUMN\s+unit_cost_snapshot'
            r'\s+REAL\s+NOT\s+NULL'
            r'[\s\S]*?DEFAULT\s+0'
            r'[\s\S]*?CHECK\s*\(\s*'
            r'unit_cost_snapshot\s*>=\s*0\s*\)',
            caseSensitive: false,
          ).hasMatch(migration),
          isTrue,
        );
      });
    });

    group('Ingredient movement audit metadata', () {
      test('adds Ingredient movement idempotency key', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'ingredient_movements',
            column: 'idempotency_key',
          ),
          isTrue,
        );
      });

      test('adds Ingredient movement Sale ID', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'ingredient_movements',
            column: 'source_sale_id',
          ),
          isTrue,
        );
      });

      test('adds Ingredient movement Sale Item ID', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'ingredient_movements',
            column: 'source_sale_item_id',
          ),
          isTrue,
        );
      });

      test('adds Ingredient movement reversal reference', () {
        expect(
          _tableAlterationContains(
            migration,
            table: 'ingredient_movements',
            column: 'reversal_of_movement_id',
          ),
          isTrue,
        );
      });

      test('adds Ingredient movement unit cost snapshot', () {
        expect(
          RegExp(
            r'ALTER\s+TABLE\s+ingredient_movements'
            r'[\s\S]*?ADD\s+COLUMN\s+unit_cost_snapshot'
            r'\s+REAL\s+NOT\s+NULL'
            r'[\s\S]*?DEFAULT\s+0'
            r'[\s\S]*?CHECK\s*\(\s*'
            r'unit_cost_snapshot\s*>=\s*0\s*\)',
            caseSensitive: false,
          ).hasMatch(migration),
          isTrue,
        );
      });
    });

    group('Movement idempotency indexes', () {
      test('creates unique Product movement idempotency index', () {
        expect(
          RegExp(
            r'CREATE\s+UNIQUE\s+INDEX\s+IF\s+NOT\s+EXISTS'
            r'\s+idx_inventory_movements_idempotency'
            r'[\s\S]*?ON\s+inventory_movements'
            r'\s*\(\s*idempotency_key\s*\)'
            r'[\s\S]*?WHERE\s+idempotency_key\s+IS\s+NOT\s+NULL',
            caseSensitive: false,
          ).hasMatch(migration),
          isTrue,
        );
      });

      test('creates unique Ingredient movement idempotency index', () {
        expect(
          RegExp(
            r'CREATE\s+UNIQUE\s+INDEX\s+IF\s+NOT\s+EXISTS'
            r'\s+idx_ingredient_movements_idempotency'
            r'[\s\S]*?ON\s+ingredient_movements'
            r'\s*\(\s*idempotency_key\s*\)'
            r'[\s\S]*?WHERE\s+idempotency_key\s+IS\s+NOT\s+NULL',
            caseSensitive: false,
          ).hasMatch(migration),
          isTrue,
        );
      });

      test('uses partial indexes for legacy null keys', () {
        expect(
          RegExp(
            r'WHERE\s+idempotency_key\s+IS\s+NOT\s+NULL',
            caseSensitive: false,
          ).allMatches(migration).length,
          greaterThanOrEqualTo(2),
        );
      });
    });

    group('Movement reversal indexes', () {
      test('creates Product movement reversal index', () {
        expect(
          RegExp(
            r'CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS'
            r'\s+idx_inventory_movements_reversal'
            r'[\s\S]*?ON\s+inventory_movements'
            r'\s*\(\s*reversal_of_movement_id\s*\)',
            caseSensitive: false,
          ).hasMatch(migration),
          isTrue,
        );
      });

      test('creates Ingredient movement reversal index', () {
        expect(
          RegExp(
            r'CREATE\s+INDEX\s+IF\s+NOT\s+EXISTS'
            r'\s+idx_ingredient_movements_reversal'
            r'[\s\S]*?ON\s+ingredient_movements'
            r'\s*\(\s*reversal_of_movement_id\s*\)',
            caseSensitive: false,
          ).hasMatch(migration),
          isTrue,
        );
      });
    });

    group('Legacy movement compatibility', () {
      test('keeps Product lineage columns nullable', () {
        for (final String column in <String>[
          'idempotency_key',
          'source_sale_id',
          'source_sale_item_id',
          'reversal_of_movement_id',
        ]) {
          expect(
            _nullableColumnDefinitionExists(
              migration,
              table: 'inventory_movements',
              column: column,
            ),
            isTrue,
            reason: '$column must remain nullable for legacy '
                'inventory movement records.',
          );
        }
      });

      test('keeps Ingredient lineage columns nullable', () {
        for (final String column in <String>[
          'idempotency_key',
          'source_sale_id',
          'source_sale_item_id',
          'reversal_of_movement_id',
        ]) {
          expect(
            _nullableColumnDefinitionExists(
              migration,
              table: 'ingredient_movements',
              column: column,
            ),
            isTrue,
            reason: '$column must remain nullable for legacy '
                'Ingredient movement records.',
          );
        }
      });

      test('does not rebuild or drop movement tables', () {
        expect(
          migration.toUpperCase(),
          isNot(
            contains(
              'DROP TABLE INVENTORY_MOVEMENTS',
            ),
          ),
        );

        expect(
          migration.toUpperCase(),
          isNot(
            contains(
              'DROP TABLE INGREDIENT_MOVEMENTS',
            ),
          ),
        );
      });

      test('does not modify inventory balances', () {
        expect(
          RegExp(
            r'UPDATE\s+inventory\b',
            caseSensitive: false,
          ).hasMatch(migration),
          isFalse,
        );

        expect(
          RegExp(
            r'UPDATE\s+ingredient_inventory\b',
            caseSensitive: false,
          ).hasMatch(migration),
          isFalse,
        );
      });
    });
  });
}

bool _tableAlterationContains(
  String source, {
  required String table,
  required String column,
}) {
  return RegExp(
    'ALTER\\s+TABLE\\s+$table'
    '[\\s\\S]*?'
    'ADD\\s+COLUMN\\s+$column\\s+TEXT',
    caseSensitive: false,
  ).hasMatch(source);
}

bool _nullableColumnDefinitionExists(
  String source, {
  required String table,
  required String column,
}) {
  final RegExp alteration = RegExp(
    'ALTER\\s+TABLE\\s+$table'
    '[\\s\\S]*?'
    'ADD\\s+COLUMN\\s+$column\\s+TEXT'
    '\\s*(?:\\n|\\r|\'\'\'|""")',
    caseSensitive: false,
  );

  final RegExp nonNullableAlteration = RegExp(
    'ALTER\\s+TABLE\\s+$table'
    '[\\s\\S]*?'
    'ADD\\s+COLUMN\\s+$column\\s+TEXT'
    '\\s+NOT\\s+NULL',
    caseSensitive: false,
  );

  return alteration.hasMatch(source) && !nonNullableAlteration.hasMatch(source);
}
