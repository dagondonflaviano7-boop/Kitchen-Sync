import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String database;
  late String constants;

  setUpAll(() {
    final File migrationFile = File(
      'lib/data/local/migrations/migration_v11.dart',
    );

    final File databaseFile = File(
      'lib/data/local/database.dart',
    );

    final File constantsFile = File(
      'lib/core/constants/app_constants.dart',
    );

    expect(
      migrationFile.existsSync(),
      isTrue,
      reason: 'Migration V11 must exist.',
    );

    expect(
      databaseFile.existsSync(),
      isTrue,
      reason: 'Database implementation must exist.',
    );

    expect(
      constantsFile.existsSync(),
      isTrue,
      reason: 'Application constants must exist.',
    );

    migration = migrationFile.readAsStringSync();
    database = databaseFile.readAsStringSync();
    constants = constantsFile.readAsStringSync();
  });

  group('Migration V11 Sale Restoration schema contract', () {
    test('exports Migration V11 statements', () {
      expect(
        migration,
        contains(
          'const List<String> migrationV11',
        ),
      );
    });

    test('creates Sale Restorations table', () {
      expect(
        migration,
        matches(
          RegExp(
            r'CREATE\s+TABLE\s+sale_restorations',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('defines Sale Restoration header columns', () {
      for (final String column in <String>[
        'id',
        'restoration_transaction_number',
        'original_sale_id',
        'operation',
        'reason',
        'subtotal',
        'discount',
        'net_sales',
        'cost',
        'cogs',
        'gross_profit',
        'gross_margin',
        'performed_by',
        'device_id',
        'occurred_at',
        'sync_status',
      ]) {
        expect(
          migration,
          contains(column),
          reason: 'sale_restorations must define $column.',
        );
      }
    });

    test('restricts supported Restoration operations', () {
      expect(
        migration,
        matches(
          RegExp(
            r'CHECK\s*\(\s*operation\s+IN\s*'
            r'\(\s*'
            r"'VOID'\s*,\s*'REFUND'"
            r'\s*\)\s*\)',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('requires unique Restoration transaction number', () {
      expect(
        migration,
        matches(
          RegExp(
            r'restoration_transaction_number'
            r'[\s\S]*?UNIQUE',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('links Restoration header to original Sale', () {
      expect(
        migration,
        matches(
          RegExp(
            r'FOREIGN\s+KEY\s*\(\s*original_sale_id\s*\)'
            r'\s+REFERENCES\s+sales\s*\(\s*id\s*\)',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('creates Sale Restoration Items table', () {
      expect(
        migration,
        matches(
          RegExp(
            r'CREATE\s+TABLE\s+sale_restoration_items',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('defines historical Restoration Item columns', () {
      for (final String column in <String>[
        'id',
        'restoration_id',
        'original_sale_item_id',
        'product_id',
        'sku',
        'product_name',
        'quantity',
        'selling_price',
        'discount',
        'net_amount',
        'unit_cost',
        'cogs',
        'recipe_version',
        'ingredient_cost_json',
      ]) {
        expect(
          migration,
          contains(column),
          reason: 'sale_restoration_items must define $column.',
        );
      }
    });

    test('links Restoration Item to header and original Item', () {
      expect(
        migration,
        matches(
          RegExp(
            r'FOREIGN\s+KEY\s*\(\s*restoration_id\s*\)'
            r'\s+REFERENCES\s+sale_restorations'
            r'\s*\(\s*id\s*\)',
            caseSensitive: false,
          ),
        ),
      );

      expect(
        migration,
        matches(
          RegExp(
            r'FOREIGN\s+KEY\s*\(\s*original_sale_item_id\s*\)'
            r'\s+REFERENCES\s+sale_items\s*\(\s*id\s*\)',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('preserves valid Restoration financial signs', () {
      for (final String column in <String>[
        'subtotal',
        'discount',
        'net_sales',
        'cost',
        'cogs',
      ]) {
        expect(
          migration,
          matches(
            RegExp(
              'CHECK\\s*\\(\\s*$column\\s*<=\\s*0\\s*\\)',
              caseSensitive: false,
            ),
          ),
          reason: '$column must be zero or negative.',
        );
      }
    });

    test('adds Restoration ownership to movement ledgers', () {
      expect(
        migration,
        matches(
          RegExp(
            r'ALTER\s+TABLE\s+inventory_movements'
            r'[\s\S]*?ADD\s+COLUMN\s+'
            r'source_restoration_id\s+TEXT',
            caseSensitive: false,
          ),
        ),
      );

      expect(
        migration,
        matches(
          RegExp(
            r'ALTER\s+TABLE\s+ingredient_movements'
            r'[\s\S]*?ADD\s+COLUMN\s+'
            r'source_restoration_id\s+TEXT',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('indexes Restoration header and Item lookups', () {
      for (final String indexName in <String>[
        'idx_sale_restorations_original_sale',
        'idx_sale_restorations_sync',
        'idx_sale_restoration_items_restoration',
        'idx_sale_restoration_items_original_item',
      ]) {
        expect(
          migration,
          contains(indexName),
          reason: 'Migration must create $indexName.',
        );
      }
    });

    test('indexes movement Restoration ownership', () {
      expect(
        migration,
        contains(
          'idx_inventory_movements_restoration',
        ),
      );

      expect(
        migration,
        contains(
          'idx_ingredient_movements_restoration',
        ),
      );

      expect(
        RegExp(
          r'ON\s+inventory_movements\s*'
          r'\(\s*source_restoration_id\s*\)',
          caseSensitive: false,
        ).hasMatch(migration),
        isTrue,
      );

      expect(
        RegExp(
          r'ON\s+ingredient_movements\s*'
          r'\(\s*source_restoration_id\s*\)',
          caseSensitive: false,
        ).hasMatch(migration),
        isTrue,
      );
    });

    test('enforces one Product reversal per original movement', () {
      expect(
        migration,
        matches(
          RegExp(
            r'CREATE\s+UNIQUE\s+INDEX\s+'
            r'IF\s+NOT\s+EXISTS\s+'
            r'idx_inventory_movements_one_reversal'
            r'[\s\S]*?'
            r'ON\s+inventory_movements\s*'
            r'\(\s*reversal_of_movement_id\s*\)'
            r'[\s\S]*?'
            r'WHERE\s+reversal_of_movement_id'
            r'\s+IS\s+NOT\s+NULL',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('enforces one Ingredient reversal per original movement', () {
      expect(
        migration,
        matches(
          RegExp(
            r'CREATE\s+UNIQUE\s+INDEX\s+'
            r'IF\s+NOT\s+EXISTS\s+'
            r'idx_ingredient_movements_one_reversal'
            r'[\s\S]*?'
            r'ON\s+ingredient_movements\s*'
            r'\(\s*reversal_of_movement_id\s*\)'
            r'[\s\S]*?'
            r'WHERE\s+reversal_of_movement_id'
            r'\s+IS\s+NOT\s+NULL',
            caseSensitive: false,
          ),
        ),
      );
    });

    test('does not replace existing idempotency safeguards', () {
      expect(
        migration.toUpperCase(),
        isNot(
          contains(
            'DROP INDEX',
          ),
        ),
      );

      expect(
        migration.toUpperCase(),
        isNot(
          contains(
            'DROP TABLE',
          ),
        ),
      );
    });

    test('updates application database Version to 11', () {
      expect(
        constants,
        matches(
          RegExp(
            r'databaseVersion\s*=\s*11',
          ),
        ),
      );
    });

    test('imports Migration V11 into database implementation', () {
      expect(
        database,
        contains(
          "import 'package:kitchen_sync/data/local/"
          "migrations/migration_v11.dart';",
        ),
      );

      expect(
        database,
        contains(
          'migrationV11',
        ),
      );
    });

    test('runs V11 during Version 10 to 11 upgrade', () {
      expect(
        database,
        contains(
          'oldVersion < 11 && newVersion >= 11',
        ),
      );

      expect(
        database,
        matches(
          RegExp(
            r'oldVersion\s*<\s*11'
            r'\s*&&\s*newVersion\s*>=\s*11'
            r'[\s\S]*?'
            r'_runStatements\s*\('
            r'[\s\S]*?'
            r'migrationV11',
          ),
        ),
      );
    });

    test('keeps migration execution inside upgrade transaction', () {
      final int transactionIndex = database.indexOf(
        'db.transaction(',
      );

      final int migrationIndex = database.indexOf(
        'migrationV11',
        transactionIndex,
      );

      expect(
        transactionIndex,
        greaterThanOrEqualTo(0),
      );

      expect(
        migrationIndex,
        greaterThan(transactionIndex),
      );
    });

    test('does not rewrite existing Sale or movement data', () {
      final String normalized = migration.toUpperCase();

      expect(
        normalized,
        isNot(
          contains(
            'UPDATE SALES',
          ),
        ),
      );

      expect(
        normalized,
        isNot(
          contains(
            'DELETE FROM SALES',
          ),
        ),
      );

      expect(
        normalized,
        isNot(
          contains(
            'DELETE FROM INVENTORY_MOVEMENTS',
          ),
        ),
      );

      expect(
        normalized,
        isNot(
          contains(
            'DELETE FROM INGREDIENT_MOVEMENTS',
          ),
        ),
      );
    });
  });
}
