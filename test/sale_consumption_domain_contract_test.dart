import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/domain/models/'
      'sale_consumption.dart',
    ).readAsStringSync();
  });

  group('Sale Consumption domain contract', () {
    test('defines Consumption item types', () {
      expect(
        source,
        contains(
          'enum ConsumptionItemType',
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

    test('defines Consumption operations', () {
      expect(
        source,
        contains(
          'enum ConsumptionOperation',
        ),
      );

      expect(
        source,
        contains(
          'ConsumptionOperation.consume',
        ),
      );

      expect(
        source,
        contains(
          'ConsumptionOperation.restore',
        ),
      );
    });

    test('defines Sale Consumption request', () {
      expect(
        source,
        contains(
          'class SaleConsumptionRequest',
        ),
      );

      for (final String field in <String>[
        'saleId',
        'saleItemId',
        'storeId',
        'productId',
        'productSku',
        'quantitySold',
        'occurredAt',
        'performedBy',
        'deviceId',
      ]) {
        expect(
          source,
          contains('final '),
        );

        expect(
          source,
          contains(field),
        );
      }
    });

    test('provides request idempotency key', () {
      expect(
        source,
        contains(
          'String get idempotencyKey',
        ),
      );

      expect(
        source,
        contains("'CONSUME'"),
      );
    });

    test('defines planned movement', () {
      expect(
        source,
        contains(
          'class PlannedInventoryMovement',
        ),
      );

      expect(
        source,
        contains(
          'final double quantityDelta',
        ),
      );

      expect(
        source,
        contains(
          'final double unitCostSnapshot',
        ),
      );

      expect(
        source,
        contains(
          'final String? '
          'reversalOfMovementId',
        ),
      );
    });

    test('preserves Recipe references', () {
      expect(
        source,
        contains(
          'final String? recipeId',
        ),
      );

      expect(
        source,
        contains(
          'final String? '
          'recipeIngredientId',
        ),
      );
    });

    test('defines Sale Consumption plan', () {
      expect(
        source,
        contains(
          'class SaleConsumptionPlan',
        ),
      );

      expect(
        source,
        contains(
          'final ProductInventoryMode '
          'inventoryMode',
        ),
      );

      expect(
        source,
        contains(
          'List<PlannedInventoryMovement>',
        ),
      );
    });

    test('enforces DIRECT movement contract', () {
      expect(
        source,
        contains(
          'DIRECT Products require exactly ',
        ),
      );

      expect(
        source,
        contains(
          'one Product movement.',
        ),
      );
    });

    test('enforces RECIPE movement contract', () {
      expect(
        source,
        contains(
          'RECIPE Products require one or ',
        ),
      );

      expect(
        source,
        contains(
          'more Ingredient movements.',
        ),
      );
    });

    test('enforces NONE movement contract', () {
      expect(
        source,
        contains(
          'NONE Products cannot create ',
        ),
      );

      expect(
        source,
        contains(
          'inventory movements.',
        ),
      );
    });

    test('protects movement idempotency', () {
      expect(
        source,
        contains(
          'Duplicate movement '
          'idempotency key.',
        ),
      );
    });

    test('supports historical cost snapshot', () {
      expect(
        source,
        contains(
          'double get totalCostSnapshot',
        ),
      );

      expect(
        source,
        contains(
          'Expected Cost must equal',
        ),
      );
    });

    test('does not write inventory balances', () {
      expect(
        source,
        isNot(
          contains(
            "database.update('inventory'",
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            "database.update("
            "'ingredient_inventory'",
          ),
        ),
      );
    });
  });
}
