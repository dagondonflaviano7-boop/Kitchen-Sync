import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/local/daos/'
      'sale_consumption_dao.dart',
    ).readAsStringSync();
  });

  group('Sale Consumption DAO contract', () {
    test('defines Sale Consumption DAO', () {
      expect(
        source,
        contains(
          'class SaleConsumptionDao',
        ),
      );
    });

    test('uses Sale Consumption domain model', () {
      expect(
        source,
        contains(
          "domain/models/sale_consumption.dart",
        ),
      );

      expect(
        source,
        contains(
          'SaleConsumptionPlan',
        ),
      );

      expect(
        source,
        contains(
          'PlannedInventoryMovement',
        ),
      );
    });

    test('uses SQLite database executor', () {
      expect(
        source,
        contains(
          'DatabaseExecutor',
        ),
      );
    });

    test('defines plan execution method', () {
      expect(
        source,
        contains(
          'Future<void> executePlan',
        ),
      );

      expect(
        source,
        contains(
          'plan.validate()',
        ),
      );
    });

    test('supports DIRECT Product movements', () {
      expect(
        source,
        contains(
          'ConsumptionItemType.product',
        ),
      );

      expect(
        source,
        contains(
          "'inventory'",
        ),
      );

      expect(
        source,
        contains(
          "'inventory_movements'",
        ),
      );
    });

    test('supports RECIPE Ingredient movements', () {
      expect(
        source,
        contains(
          'ConsumptionItemType.ingredient',
        ),
      );

      expect(
        source,
        contains(
          "'ingredient_inventory'",
        ),
      );

      expect(
        source,
        contains(
          "'ingredient_movements'",
        ),
      );
    });

    test('supports NONE mode as no-op', () {
      expect(
        source,
        contains(
          'ProductInventoryMode.none',
        ),
      );

      expect(
        source,
        contains(
          'return;',
        ),
      );
    });

    test('checks movement idempotency', () {
      expect(
        source,
        contains(
          'idempotency_key = ?',
        ),
      );

      expect(
        source,
        contains(
          'movement.idempotencyKey.trim()',
        ),
      );
    });

    test('reads Product inventory balance', () {
      expect(
        source,
        contains(
          'store_id = ? AND product_id = ?',
        ),
      );
    });

    test('reads Ingredient inventory balance', () {
      expect(
        source,
        contains(
          'store_id = ? AND ingredient_id = ?',
        ),
      );
    });

    test('updates Product inventory balance', () {
      expect(
        source,
        contains(
          "database.update(\n      'inventory'",
        ),
      );
    });

    test('updates Ingredient inventory balance', () {
      expect(
        source,
        contains(
          "database.update(\n      'ingredient_inventory'",
        ),
      );
    });

    test('stores before and after quantities', () {
      expect(
        source,
        contains(
          "'before_quantity'",
        ),
      );

      expect(
        source,
        contains(
          "'after_quantity'",
        ),
      );
    });

    test('stores movement quantity delta', () {
      expect(
        source,
        contains(
          "'quantity': movement.quantityDelta",
        ),
      );
    });

    test('stores movement operation', () {
      expect(
        source,
        contains(
          'consumptionOperationToStorage',
        ),
      );

      expect(
        source,
        contains(
          "'movement_type'",
        ),
      );
    });

    test('stores Sale lineage', () {
      expect(
        source,
        contains(
          "'source_sale_id'",
        ),
      );

      expect(
        source,
        contains(
          "'source_sale_item_id'",
        ),
      );

      expect(
        source,
        contains(
          "'reference_id'",
        ),
      );
    });

    test('stores movement idempotency key', () {
      expect(
        source,
        contains(
          "'idempotency_key'",
        ),
      );
    });

    test('stores restoration reference', () {
      expect(
        source,
        contains(
          "'reversal_of_movement_id'",
        ),
      );
    });

    test('stores Ingredient Recipe lineage', () {
      expect(
        source,
        contains(
          "'recipe_id'",
        ),
      );

      expect(
        source,
        contains(
          'movement.recipeId',
        ),
      );

      expect(
        source,
        contains(
          "'recipe_ingredient_id'",
        ),
      );

      expect(
        source,
        contains(
          'movement.recipeIngredientId',
        ),
      );

      expect(
        source,
        contains(
          'movement.isIngredientMovement',
        ),
      );
    });

    test('stores historical unit cost snapshot', () {
      expect(
        source,
        contains(
          "'unit_cost_snapshot'",
        ),
      );

      expect(
        source,
        contains(
          'movement.unitCostSnapshot',
        ),
      );
    });

    test('stores user and device audit values', () {
      expect(
        source,
        contains(
          "'user_id'",
        ),
      );

      expect(
        source,
        contains(
          "'device_id'",
        ),
      );
    });

    test('stores movement timestamp', () {
      expect(
        source,
        contains(
          "'created_at'",
        ),
      );

      expect(
        source,
        contains(
          'movement.occurredAt',
        ),
      );

      expect(
        source,
        contains(
          'toUtc().toIso8601String()',
        ),
      );
    });

    test('creates deterministic movement IDs', () {
      expect(
        source,
        contains(
          '_movementId',
        ),
      );

      expect(
        source,
        contains(
          'movement.idempotencyKey',
        ),
      );
    });

    test('does not use conflict replace for movements', () {
      expect(
        source,
        isNot(
          contains(
            'ConflictAlgorithm.replace',
          ),
        ),
      );
    });

    test('rejects missing inventory balance rows', () {
      expect(
        source,
        contains(
          'Inventory balance was not found.',
        ),
      );

      expect(
        source,
        contains(
          'Ingredient Inventory balance was not found.',
        ),
      );
    });

    test('requires exactly one balance row update', () {
      expect(
        source,
        contains(
          'updated != 1',
        ),
      );
    });

    test('provides processed movement lookup', () {
      expect(
        source,
        contains(
          'Future<bool> hasProcessedMovement',
        ),
      );
    });

    test('validates restoration original movement', () {
      expect(
        source,
        contains(
          'reversalOfMovementId',
        ),
      );

      expect(
        source,
        contains(
          'Original movement was not found.',
        ),
      );
    });

    test('prevents duplicate restoration', () {
      expect(
        source,
        contains(
          'reversal_of_movement_id = ?',
        ),
      );

      expect(
        source,
        contains(
          'Original movement was already restored.',
        ),
      );
    });

    test('does not open its own database transaction', () {
      expect(
        source,
        isNot(
          contains(
            'AppDatabase.instance.database',
          ),
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
    });
  });
}
