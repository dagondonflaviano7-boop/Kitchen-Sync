import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File costingFile = File(
      'lib/domain/models/sale_posting_costing.dart',
    );

    expect(
      costingFile.existsSync(),
      isTrue,
      reason: 'Sale Posting costing domain must exist.',
    );

    source = costingFile.readAsStringSync();
  });

  group('Sale Posting costing domain contract', () {
    test('defines item costing snapshot', () {
      expect(
        source,
        contains(
          'class SalePostingItemCostSnapshot',
        ),
      );

      for (final String field in <String>[
        'saleItemId',
        'productId',
        'inventoryMode',
        'quantity',
        'netAmount',
        'unitCost',
        'cogs',
        'grossProfit',
        'grossMargin',
        'recipeId',
        'recipeVersion',
        'ingredientCostJson',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'Item costing snapshot must define $field.',
        );
      }
    });

    test('defines sale costing snapshot', () {
      expect(
        source,
        contains(
          'class SalePostingCostingSnapshot',
        ),
      );

      for (final String field in <String>[
        'saleId',
        'items',
        'totalCost',
        'totalCogs',
        'grossProfit',
        'grossMargin',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'Sale costing snapshot must define $field.',
        );
      }
    });

    test('defines authoritative costing planner', () {
      expect(
        source,
        contains(
          'class SalePostingCostingPlanner',
        ),
      );

      expect(
        source,
        contains(
          'const SalePostingCostingPlanner()',
        ),
      );

      expect(
        source,
        contains(
          'SalePostingCostingSnapshot createSnapshot(',
        ),
      );
    });

    test('uses Sale Posting request and consumption plans', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/domain/models/sale_posting.dart'",
        ),
      );

      expect(
        source,
        contains(
          "import 'package:kitchen_sync/domain/models/sale_consumption.dart'",
        ),
      );

      expect(
        source,
        contains(
          'SalePostingRequest request',
        ),
      );

      expect(
        source,
        contains(
          'List<SaleConsumptionPlan> plans',
        ),
      );
    });

    test('uses expected plan cost as authoritative COGS', () {
      expect(
        source,
        contains(
          'plan.expectedCost',
        ),
      );

      expect(
        source,
        contains(
          'final double cogs',
        ),
      );

      expect(
        source,
        contains(
          'final double unitCost',
        ),
      );
    });

    test('supports all Product inventory modes', () {
      expect(
        source,
        contains(
          'ProductInventoryMode.direct',
        ),
      );

      expect(
        source,
        contains(
          'ProductInventoryMode.recipe',
        ),
      );

      expect(
        source,
        contains(
          'ProductInventoryMode.none',
        ),
      );
    });

    test('calculates item profitability from net amount', () {
      expect(
        source,
        contains(
          'item.netAmount',
        ),
      );

      expect(
        source,
        contains(
          'double get grossProfit',
        ),
      );

      expect(
        source,
        contains(
          'double get grossMargin',
        ),
      );
    });

    test('calculates sale profitability', () {
      expect(
        source,
        contains(
          'double get totalCost',
        ),
      );

      expect(
        source,
        contains(
          'double get totalCogs',
        ),
      );

      expect(
        source,
        contains(
          'double get grossProfit',
        ),
      );

      expect(
        source,
        contains(
          'double get grossMargin',
        ),
      );
    });

    test('uses zero-safe gross margin calculation', () {
      expect(
        source,
        contains(
          'netAmount <= 0',
        ),
      );

      expect(
        source,
        contains(
          'request.grandTotal <= 0',
        ),
      );

      expect(
        source,
        contains(
          'return 0',
        ),
      );
    });

    test('allows negative gross profit', () {
      expect(
        source,
        contains(
          'netAmount - cogs',
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'Gross Profit cannot be negative.',
          ),
        ),
      );
    });

    test('preserves Recipe costing references', () {
      expect(
        source,
        contains(
          'final String? recipeId',
        ),
      );

      expect(
        source,
        contains(
          'final int? recipeVersion',
        ),
      );

      expect(
        source,
        contains(
          'final String? ingredientCostJson',
        ),
      );

      expect(
        source,
        contains(
          'recipeVersion: null',
        ),
        reason: 'Recipe version must remain null until a business '
            'Recipe version source exists.',
      );
    });

    test('generates deterministic Ingredient costing JSON', () {
      expect(
        source,
        contains(
          "import 'dart:convert'",
        ),
      );

      expect(
        source,
        contains(
          'jsonEncode(',
        ),
      );

      expect(
        source,
        contains(
          'recipeIngredientId',
        ),
      );

      expect(
        source,
        contains(
          'ingredientId',
        ),
      );

      expect(
        source,
        contains(
          'ingredientCode',
        ),
      );

      expect(
        source,
        contains(
          'unitCode',
        ),
      );

      expect(
        source,
        contains(
          'quantity',
        ),
      );

      expect(
        source,
        contains(
          'unitCost',
        ),
      );

      expect(
        source,
        contains(
          'extendedCost',
        ),
      );

      expect(
        source,
        contains(
          'totalIngredientCost',
        ),
      );

      expect(
        source,
        contains(
          'sort(',
        ),
        reason: 'Ingredient lines must be sorted before JSON encoding.',
      );
    });

    test('omits Ingredient JSON for DIRECT and NONE items', () {
      expect(
        source,
        contains(
          'ingredientCostJson: null',
        ),
      );
    });

    test('protects immutable item snapshots', () {
      expect(
        source,
        contains(
          'List<SalePostingItemCostSnapshot>.unmodifiable',
        ),
      );
    });

    test('finds costing snapshot by Sale Item ID', () {
      expect(
        source,
        contains(
          'SalePostingItemCostSnapshot itemCostFor(',
        ),
      );

      expect(
        source,
        contains(
          'saleItemId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Cost snapshot was not found for Sale Item.',
        ),
      );
    });

    test('validates request and plan ownership', () {
      expect(
        source,
        contains(
          'request.validate()',
        ),
      );

      expect(
        source,
        contains(
          'plan.validate()',
        ),
      );

      expect(
        source,
        contains(
          'plan.request.saleId',
        ),
      );

      expect(
        source,
        contains(
          'plan.request.saleItemId',
        ),
      );

      expect(
        source,
        contains(
          'plan.request.productId',
        ),
      );

      expect(
        source,
        contains(
          'Costing plan does not belong to the Sale.',
        ),
      );

      expect(
        source,
        contains(
          'Costing plan does not match the Sale Item.',
        ),
      );
    });

    test('requires exactly one plan per Sale Item', () {
      expect(
        source,
        contains(
          'plans.length != request.items.length',
        ),
      );

      expect(
        source,
        contains(
          'Every Sale Item must have exactly one costing plan.',
        ),
      );

      expect(
        source,
        contains(
          'Duplicate Sale Item costing plan.',
        ),
      );
    });

    test('rejects duplicate item snapshots', () {
      expect(
        source,
        contains(
          'Duplicate Sale Item cost snapshot.',
        ),
      );
    });

    test('validates finite and non-negative cost values', () {
      expect(
        source,
        contains(
          'isFinite',
        ),
      );

      expect(
        source,
        contains(
          'cannot be negative',
        ),
      );

      expect(
        source,
        contains(
          'must be a valid number',
        ),
      );
    });

    test('validates complete costing snapshots', () {
      expect(
        source,
        contains(
          'void validate()',
        ),
      );

      expect(
        source,
        contains(
          'items.isEmpty',
        ),
      );

      expect(
        source,
        contains(
          'Sale costing requires at least one Item snapshot.',
        ),
      );
    });

    test('normalizes identifiers and Recipe references', () {
      expect(
        source,
        contains(
          'trim()',
        ),
      );

      expect(
        source,
        contains(
          'toUpperCase()',
        ),
      );
    });
  });
}
