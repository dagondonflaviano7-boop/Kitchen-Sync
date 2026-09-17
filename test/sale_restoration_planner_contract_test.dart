import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File file = File(
      'lib/domain/services/sale_restoration_planner.dart',
    );

    expect(
      file.existsSync(),
      isTrue,
      reason: 'Sale Restoration Planner must exist.',
    );

    source = file.readAsStringSync().replaceAll(
          RegExp(r"'\s*\n\s*'"),
          '',
        );
  });

  void containsAll(
    List<String> values, {
    String? reason,
  }) {
    for (final String value in values) {
      expect(
        source,
        contains(value),
        reason: reason ?? 'Planner must contain $value.',
      );
    }
  }

  group('Sale Restoration Planner contract', () {
    test('defines historical snapshot models', () {
      containsAll(<String>[
        'class HistoricalSaleSnapshot',
        'class HistoricalSaleItemSnapshot',
        'class HistoricalSaleMovementSnapshot',
      ]);
    });

    test('defines historical Sale fields', () {
      containsAll(<String>[
        'saleId',
        'transactionNumber',
        'storeId',
        'status',
        'subtotal',
        'discount',
        'netSales',
        'cost',
        'cogs',
        'grossProfit',
        'grossMargin',
        'items',
      ]);
    });

    test('defines historical Item costing fields', () {
      containsAll(<String>[
        'saleItemId',
        'productId',
        'productSku',
        'productName',
        'quantity',
        'sellingPrice',
        'netAmount',
        'unitCost',
        'recipeVersion',
        'ingredientCostJson',
      ]);
    });

    test('defines historical movement fields', () {
      containsAll(<String>[
        'movementId',
        'itemType',
        'itemId',
        'itemCode',
        'unitCode',
        'quantityDelta',
        'unitCostSnapshot',
        'sourceSaleId',
        'sourceSaleItemId',
        'recipeId',
        'recipeIngredientId',
        'reversalOfMovementId',
      ]);
    });

    test('defines planner and createPlan', () {
      containsAll(<String>[
        'class SaleRestorationPlanner',
        'const SaleRestorationPlanner()',
        'SaleRestorationPlan createPlan(',
        'SaleRestorationRequest request',
        'HistoricalSaleSnapshot sale',
        'List<HistoricalSaleMovementSnapshot> movements',
      ]);
    });

    test('requires completed matching Sale', () {
      containsAll(<String>[
        "'COMPLETED'",
        'Only a completed Sale can be restored.',
        'request.originalSaleId.trim()',
        'sale.saleId.trim()',
        'Restoration request does not match the original Sale.',
      ]);
    });

    test('copies historical Item costing', () {
      containsAll(<String>[
        'SaleRestorationItemPlan(',
        'originalSaleItemId:',
        'unitCost: item.unitCost',
        'cogs: item.cogs',
        'recipeVersion: item.recipeVersion',
        'ingredientCostJson: item.ingredientCostJson',
      ]);
    });

    test('creates exact inverse movements', () {
      containsAll(<String>[
        'SaleRestorationMovementPlan(',
        'originalMovementId: movement.movementId',
        'reversalOfMovementId: movement.movementId',
        'quantityDelta: -movement.quantityDelta',
        'unitCostSnapshot: movement.unitCostSnapshot',
        'itemType: movement.itemType',
      ]);
    });

    test('preserves Recipe lineage', () {
      containsAll(<String>[
        'recipeId: movement.recipeId',
        'recipeIngredientId: movement.recipeIngredientId',
        'ConsumptionItemType.product',
        'ConsumptionItemType.ingredient',
      ]);
    });

    test('validates historical movements', () {
      containsAll(<String>[
        'quantityDelta >= 0',
        'Original movement must have a negative quantity.',
        'Original movement was already restored.',
        'Historical movement does not belong to the original Sale.',
        'Historical movement does not match a Sale Item.',
        'Historical movement does not belong to the Sale Store.',
        'Duplicate historical movement.',
      ]);
    });

    test('supports NONE Items and requires tracked movements', () {
      containsAll(<String>[
        'cogs == 0',
        'unitCost == 0',
        'Historical inventory movement was not found for Sale Item.',
      ]);
    });

    test('reconciles historical COGS', () {
      containsAll(<String>[
        'movement.quantityDelta.abs()',
        'movement.unitCostSnapshot',
        'Historical movement cost does not match Sale Item COGS.',
        'static const double',
        'tolerance',
      ]);
    });

    test('creates signed financial reversal', () {
      containsAll(<String>[
        'subtotalReversal: -sale.subtotal',
        'discountReversal: -sale.discount',
        'netSalesReversal: -sale.netSales',
        'costReversal: -sale.cost',
        'cogsReversal: -sale.cogs',
        'grossProfitReversal: -sale.grossProfit',
        'grossMarginSnapshot: sale.grossMargin',
      ]);
    });

    test('generates IDs and validates final plan', () {
      containsAll(<String>[
        'String _restorationItemId(',
        'String _restorationMovementId(',
        'request.restorationId.trim()',
        'movement.movementId.trim()',
        'plan.validate()',
      ]);
    });

    test('remains database and master-data independent', () {
      for (final String forbidden in <String>[
        'DatabaseExecutor',
        'database.',
        'ProductDao',
        'RecipeDao',
        'IngredientDao',
        'product.cost',
        'ingredient.cost',
        'Repository',
        'database.transaction',
      ]) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: 'Planner must not depend on $forbidden.',
        );
      }
    });
  });
}
