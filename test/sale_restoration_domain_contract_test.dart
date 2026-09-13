import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File domainFile = File(
      'lib/domain/models/sale_restoration.dart',
    );

    expect(
      domainFile.existsSync(),
      isTrue,
      reason: 'Sale Restoration domain must exist.',
    );

    source = domainFile.readAsStringSync().replaceAll(
          RegExp(r"'\s*'"),
          '',
        );
  });

  group('Sale Restoration domain contract', () {
    test('defines supported restoration operations', () {
      expect(
        source,
        contains(
          'enum SaleRestorationOperation',
        ),
      );

      expect(
        source,
        contains(
          'voidSale',
        ),
      );

      expect(
        source,
        contains(
          'refund',
        ),
      );
    });

    test('defines restoration operation storage mapping', () {
      expect(
        source,
        contains(
          'String saleRestorationOperationToStorage(',
        ),
      );

      expect(
        source,
        contains(
          'SaleRestorationOperation '
          'saleRestorationOperationFromStorage(',
        ),
      );

      expect(
        source,
        contains(
          "'VOID'",
        ),
      );

      expect(
        source,
        contains(
          "'REFUND'",
        ),
      );
    });

    test('defines Sale Restoration request', () {
      expect(
        source,
        contains(
          'class SaleRestorationRequest',
        ),
      );

      for (final String field in <String>[
        'restorationId',
        'restorationTransactionNumber',
        'originalSaleId',
        'operation',
        'reason',
        'performedBy',
        'deviceId',
        'occurredAt',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'Restoration request must define $field.',
        );
      }
    });

    test('defines immutable Restoration request', () {
      expect(
        source,
        contains(
          'const SaleRestorationRequest(',
        ),
      );

      expect(
        source,
        contains(
          'final String restorationId',
        ),
      );

      expect(
        source,
        contains(
          'final SaleRestorationOperation operation',
        ),
      );

      expect(
        source,
        contains(
          'final DateTime occurredAt',
        ),
      );
    });

    test('requires a meaningful Restoration reason', () {
      expect(
        source,
        contains(
          'reason.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Restoration reason is required.',
        ),
      );
    });

    test('defines Restoration Item plan', () {
      expect(
        source,
        contains(
          'class SaleRestorationItemPlan',
        ),
      );

      for (final String field in <String>[
        'restorationItemId',
        'originalSaleItemId',
        'productId',
        'productSku',
        'productName',
        'quantity',
        'sellingPrice',
        'discount',
        'netAmount',
        'unitCost',
        'cogs',
        'recipeVersion',
        'ingredientCostJson',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'Restoration Item plan must define $field.',
        );
      }
    });

    test('preserves historical Sale Item costing', () {
      expect(
        source,
        contains(
          'final double unitCost',
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
          'final int? recipeVersion',
        ),
      );

      expect(
        source,
        contains(
          'final String? ingredientCostJson',
        ),
      );
    });

    test('defines Restoration movement plan', () {
      expect(
        source,
        contains(
          'class SaleRestorationMovementPlan',
        ),
      );

      for (final String field in <String>[
        'restorationMovementId',
        'originalMovementId',
        'itemType',
        'itemId',
        'itemCode',
        'unitCode',
        'quantityDelta',
        'unitCostSnapshot',
        'originalSaleId',
        'originalSaleItemId',
        'storeId',
        'recipeId',
        'recipeIngredientId',
        'reversalOfMovementId',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'Restoration movement must define $field.',
        );
      }
    });

    test('links every Restoration to its original movement', () {
      expect(
        source,
        contains(
          'final String originalMovementId',
        ),
      );

      expect(
        source,
        contains(
          'final String reversalOfMovementId',
        ),
      );

      expect(
        source,
        contains(
          'reversalOfMovementId.trim() != '
          'originalMovementId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Restoration movement must reference its '
          'original movement.',
        ),
      );
    });

    test('requires positive Restoration movement quantity', () {
      expect(
        source,
        contains(
          'quantityDelta <= 0',
        ),
      );

      expect(
        source,
        contains(
          'Restoration movement quantity must be '
          'greater than zero.',
        ),
      );
    });

    test('preserves historical movement unit cost', () {
      expect(
        source,
        contains(
          'unitCostSnapshot',
        ),
      );

      expect(
        source,
        contains(
          'Restoration movement unit cost',
        ),
      );
    });

    test('supports Product and Ingredient movements', () {
      expect(
        source,
        contains(
          'ConsumptionItemType itemType',
        ),
      );

      expect(
        source,
        contains(
          'ConsumptionItemType.product',
        ),
      );

      expect(
        source,
        contains(
          'ConsumptionItemType.ingredient',
        ),
      );
    });

    test('requires Recipe lineage for Ingredient restoration', () {
      expect(
        source,
        contains(
          'itemType == ConsumptionItemType.ingredient',
        ),
      );

      expect(
        source,
        contains(
          'Ingredient restoration requires a Recipe ID.',
        ),
      );

      expect(
        source,
        contains(
          'Ingredient restoration requires a '
          'Recipe Ingredient ID.',
        ),
      );
    });

    test('prevents Recipe lineage on Product restoration', () {
      expect(
        source,
        contains(
          'Product restoration cannot contain Recipe lineage.',
        ),
      );
    });

    test('defines complete Sale Restoration plan', () {
      expect(
        source,
        contains(
          'class SaleRestorationPlan',
        ),
      );

      for (final String field in <String>[
        'request',
        'originalTransactionNumber',
        'storeId',
        'items',
        'movements',
        'subtotalReversal',
        'discountReversal',
        'netSalesReversal',
        'costReversal',
        'cogsReversal',
        'grossProfitReversal',
        'grossMarginSnapshot',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'Restoration plan must define $field.',
        );
      }
    });

    test('protects immutable Item and movement collections', () {
      expect(
        source,
        contains(
          'List<SaleRestorationItemPlan>.unmodifiable',
        ),
      );

      expect(
        source,
        contains(
          'List<SaleRestorationMovementPlan>.unmodifiable',
        ),
      );
    });

    test('requires at least one Restoration Item', () {
      expect(
        source,
        contains(
          'items.isEmpty',
        ),
      );

      expect(
        source,
        contains(
          'Sale Restoration requires at least one Item.',
        ),
      );
    });

    test('rejects duplicate original Sale Item plans', () {
      expect(
        source,
        contains(
          'Duplicate original Sale Item restoration.',
        ),
      );
    });

    test('rejects duplicate original movement restoration', () {
      expect(
        source,
        contains(
          'Duplicate original movement restoration.',
        ),
      );
    });

    test('requires plan records to belong to original Sale', () {
      expect(
        source,
        contains(
          'request.originalSaleId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'movement.originalSaleId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Restoration movement does not belong to '
          'the original Sale.',
        ),
      );
    });

    test('requires movements to reference planned Items', () {
      expect(
        source,
        contains(
          'movement.originalSaleItemId.trim()',
        ),
      );

      expect(
        source,
        contains(
          'Restoration movement does not match a '
          'Restoration Item.',
        ),
      );
    });

    test('defines Restoration request idempotency key', () {
      expect(
        source,
        contains(
          'String get idempotencyKey',
        ),
      );

      expect(
        source,
        contains(
          "'RESTORE:",
        ),
      );

      expect(
        source,
        contains(
          'saleRestorationOperationToStorage(',
        ),
      );

      expect(
        source,
        contains(
          'originalSaleId.trim()',
        ),
      );
    });

    test('defines Restoration movement idempotency key', () {
      expect(
        source,
        contains(
          "'RESTORE:\$restorationId:",
        ),
      );

      expect(
        source,
        contains(
          'originalMovementId.trim()',
        ),
      );
    });

    test('supports signed financial reversal values', () {
      expect(
        source,
        contains(
          'subtotalReversal',
        ),
      );

      expect(
        source,
        contains(
          'netSalesReversal',
        ),
      );

      expect(
        source,
        contains(
          'cogsReversal',
        ),
      );

      expect(
        source,
        contains(
          'grossProfitReversal',
        ),
      );

      expect(
        source,
        contains(
          'must be zero or negative',
        ),
      );
    });

    test('allows negative Restoration gross profit', () {
      expect(
        source,
        isNot(
          contains(
            'Restoration gross profit cannot be negative.',
          ),
        ),
      );

      expect(
        source,
        contains(
          'grossProfitReversal',
        ),
      );
    });

    test('preserves original gross-margin snapshot', () {
      expect(
        source,
        contains(
          'final double grossMarginSnapshot',
        ),
      );

      expect(
        source,
        contains(
          'Restoration gross-margin snapshot',
        ),
      );
    });

    test('validates finite financial and costing values', () {
      expect(
        source,
        contains(
          'isFinite',
        ),
      );

      expect(
        source,
        contains(
          'must be a valid number',
        ),
      );
    });

    test('validates non-negative quantity and costs', () {
      expect(
        source,
        contains(
          'cannot be negative',
        ),
      );

      expect(
        source,
        contains(
          'must be greater than zero',
        ),
      );
    });

    test('normalizes identifiers and storage codes', () {
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

    test('provides Item lookup by original Sale Item ID', () {
      expect(
        source,
        contains(
          'SaleRestorationItemPlan itemForOriginalSaleItem(',
        ),
      );

      expect(
        source,
        contains(
          'Restoration Item was not found.',
        ),
      );
    });

    test('provides movement lookup by original movement ID', () {
      expect(
        source,
        contains(
          'SaleRestorationMovementPlan movementForOriginalMovement(',
        ),
      );

      expect(
        source,
        contains(
          'Restoration movement was not found.',
        ),
      );
    });

    test('validates all domain records', () {
      expect(
        RegExp(
          r'void\s+validate\s*\(\s*\)',
        ).allMatches(source).length,
        greaterThanOrEqualTo(4),
        reason: 'Request, Item, movement, and plan must validate.',
      );
    });

    test('does not load current master costs', () {
      expect(
        source,
        isNot(
          contains(
            'ProductDao',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'RecipeDao',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'IngredientDao',
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
            'ingredient.cost',
          ),
        ),
      );
    });

    test('does not perform database operations', () {
      expect(
        source,
        isNot(
          contains(
            'DatabaseExecutor',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'database.insert',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'database.transaction',
          ),
        ),
      );
    });
  });
}
