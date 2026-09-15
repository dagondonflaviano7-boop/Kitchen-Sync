import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File daoFile = File(
      'lib/data/local/daos/sale_posting_dao.dart',
    );

    expect(
      daoFile.existsSync(),
      isTrue,
      reason: 'Sale Posting DAO must exist.',
    );

    source = daoFile.readAsStringSync();
  });

  group('Sale Posting costing persistence DAO contract', () {
    test('imports authoritative costing domain', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/domain/models/"
          "sale_posting_costing.dart'",
        ),
      );
    });

    test('insertSale requires costing snapshot', () {
      expect(
        source,
        matches(
          RegExp(
            r'Future<void>\s+insertSale\s*\('
            r'[\s\S]*?DatabaseExecutor\s+database\s*,'
            r'[\s\S]*?SalePostingRequest\s+request\s*,'
            r'[\s\S]*?SalePostingCostingSnapshot\s+costing\s*,?'
            r'[\s\S]*?\)\s+async',
          ),
        ),
      );
    });

    test('insertSaleItems requires costing snapshot', () {
      expect(
        source,
        matches(
          RegExp(
            r'Future<void>\s+insertSaleItems\s*\('
            r'[\s\S]*?DatabaseExecutor\s+database\s*,'
            r'[\s\S]*?SalePostingRequest\s+request\s*,'
            r'[\s\S]*?SalePostingCostingSnapshot\s+costing\s*,?'
            r'[\s\S]*?\)\s+async',
          ),
        ),
      );
    });

    test('insertPosting requires costing snapshot', () {
      expect(
        source,
        matches(
          RegExp(
            r'Future<void>\s+insertPosting\s*\('
            r'[\s\S]*?DatabaseExecutor\s+database\s*,'
            r'[\s\S]*?SalePostingRequest\s+request\s*,'
            r'[\s\S]*?SalePostingCostingSnapshot\s+costing\s*,?'
            r'[\s\S]*?\)\s+async',
          ),
        ),
      );
    });

    test('validates authoritative costing before writing', () {
      expect(
        source,
        contains(
          'costing.validate()',
        ),
      );

      expect(
        source,
        contains(
          'costing.saleId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'request.saleId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Costing snapshot does not belong to the Sale.',
        ),
      );
    });

    test('persists authoritative sale totals', () {
      expect(
        source,
        contains(
          "'cost': costing.totalCost",
        ),
      );

      expect(
        source,
        contains(
          "'cogs': costing.totalCogs",
        ),
      );

      expect(
        source,
        contains(
          "'gross_profit': costing.grossProfit",
        ),
      );

      expect(
        source,
        contains(
          "'gross_margin': costing.grossMargin",
        ),
      );
    });

    test('finds authoritative cost for each Sale Item', () {
      expect(
        source,
        contains(
          'final SalePostingItemCostSnapshot itemCost',
        ),
      );

      expect(
        source,
        contains(
          'costing.itemCostFor(',
        ),
      );

      expect(
        source,
        contains(
          'item.id',
        ),
      );
    });

    test('validates each matched item cost snapshot', () {
      expect(
        source,
        contains(
          'itemCost.validate()',
        ),
      );

      expect(
        source,
        contains(
          'itemCost.saleItemId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'item.id.trim()',
        ),
      );

      expect(
        source,
        contains(
          'itemCost.productId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'item.productId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Cost snapshot does not match the Sale Item.',
        ),
      );
    });

    test('persists authoritative Sale Item costing', () {
      expect(
        source,
        contains(
          "'unit_cost': itemCost.unitCost",
        ),
      );

      expect(
        source,
        contains(
          "'cogs': itemCost.cogs",
        ),
      );

      expect(
        source,
        contains(
          "'recipe_version': itemCost.recipeVersion",
        ),
      );

      expect(
        source,
        contains(
          "'ingredient_cost_json': itemCost.ingredientCostJson",
        ),
      );
    });

    test('passes costing snapshot through complete posting entry point', () {
      expect(
        source,
        matches(
          RegExp(
            r'await\s+insertSale\s*\('
            r'[\s\S]*?database\s*,'
            r'[\s\S]*?request\s*,'
            r'[\s\S]*?costing\s*,?'
            r'[\s\S]*?\)\s*;',
          ),
        ),
      );

      expect(
        source,
        matches(
          RegExp(
            r'await\s+insertSaleItems\s*\('
            r'[\s\S]*?database\s*,'
            r'[\s\S]*?request\s*,'
            r'[\s\S]*?costing\s*,?'
            r'[\s\S]*?\)\s*;',
          ),
        ),
      );

      expect(
        source,
        contains(
          'await insertPayments(',
        ),
      );
    });

    test('removes zero Sale costing placeholders', () {
      expect(
        source,
        isNot(
          contains(
            "'cost': 0.0",
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            "'cogs': 0.0",
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            "'gross_profit': 0.0",
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            "'gross_margin': 0.0",
          ),
        ),
      );
    });

    test('removes zero Sale Item costing placeholders', () {
      expect(
        source,
        isNot(
          contains(
            "'unit_cost': 0.0",
          ),
        ),
      );
    });

    test('does not recalculate authoritative COGS in DAO', () {
      expect(
        source,
        isNot(
          contains(
            'item.quantity *',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'product.cost',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'plan.expectedCost',
          ),
        ),
      );
    });

    test('keeps DAO transaction neutral', () {
      expect(
        source,
        contains(
          'DatabaseExecutor database',
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'database.transaction(',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'AppDatabase.instance.database',
          ),
        ),
      );
    });

    test('remains valid after the restoration schema migration', () {
      final File constantsFile = File(
        'lib/core/constants/app_constants.dart',
      );

      expect(
        constantsFile.readAsStringSync(),
        contains(
          'databaseVersion = 11',
        ),
      );

      expect(
        File(
          'lib/data/local/migrations/migration_v11.dart',
        ).existsSync(),
        isTrue,
      );
    });
  });
}
