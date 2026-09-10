import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/domain/services/'
      'sale_consumption_planner.dart',
    ).readAsStringSync();
  });

  group('Sale Consumption Planner contract', () {
    test('defines planner and createPlan', () {
      expect(
        source,
        contains(
          'class SaleConsumptionPlanner',
        ),
      );

      expect(
        source,
        contains(
          'SaleConsumptionPlan createPlan(',
        ),
      );
    });

    test('supports every Inventory Mode', () {
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

    test('creates DIRECT Product movement', () {
      expect(
        source,
        contains(
          'ConsumptionItemType.product',
        ),
      );

      expect(
        source,
        contains(
          "unitCode: 'EACH'",
        ),
      );

      expect(
        source,
        contains(
          'quantityDelta: -quantity',
        ),
      );
    });

    test('creates RECIPE Ingredient movements', () {
      expect(
        source,
        contains(
          'ConsumptionItemType.ingredient',
        ),
      );

      expect(
        source,
        contains(
          'ingredient.quantityRequired *',
        ),
      );

      expect(
        source,
        contains(
          'recipeIngredientId:',
        ),
      );
    });

    test('scales Recipe by its yield', () {
      expect(
        source,
        contains(
          'request.quantitySold /',
        ),
      );

      expect(
        source,
        contains(
          'recipe.yieldQuantity',
        ),
      );
    });

    test('creates no movements for NONE', () {
      expect(
        source,
        contains(
          'const <PlannedInventoryMovement>[]',
        ),
      );

      expect(
        source,
        contains(
          'expectedCost: 0',
        ),
      );
    });

    test('validates Product references', () {
      expect(
        source,
        contains(
          'Sale Product ID does not match ',
        ),
      );

      expect(
        source,
        contains(
          'Sale Product SKU does not match ',
        ),
      );
    });

    test('validates Recipe references', () {
      expect(
        source,
        contains(
          'Loaded Recipe does not match ',
        ),
      );

      expect(
        source,
        contains(
          'The linked Recipe is required ',
        ),
      );
    });

    test('rejects inactive records', () {
      expect(
        source,
        contains(
          'Sale consumption requires '
          'an active Product.',
        ),
      );

      expect(
        source,
        contains(
          'Sale consumption requires ',
        ),
      );

      expect(
        source,
        contains(
          'an active Recipe.',
        ),
      );
    });

    test('generates deterministic keys', () {
      expect(
        source,
        contains(
          'String _movementKey(',
        ),
      );

      expect(
        source,
        contains(
          "parts.add('CONSUME')",
        ),
      );

      expect(
        source,
        contains(
          'recipeIngredientId',
        ),
      );
    });

    test('validates completed plan', () {
      expect(
        source,
        contains(
          'plan.validate()',
        ),
      );
    });

    test('does not write database state', () {
      expect(
        source,
        isNot(
          contains('Database'),
        ),
      );

      expect(
        source,
        isNot(
          contains('database.insert'),
        ),
      );

      expect(
        source,
        isNot(
          contains('database.update'),
        ),
      );

      expect(
        source,
        isNot(
          contains('Transaction'),
        ),
      );
    });
  });
}
