import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/services/sale_consumption_planner.dart';

void main() {
  const SaleConsumptionPlanner planner = SaleConsumptionPlanner();

  SaleConsumptionRequest request({
    String productId = 'product-001',
    String productSku = 'SKU-001',
    double quantitySold = 4,
  }) {
    return SaleConsumptionRequest(
      saleId: 'sale-001',
      saleItemId: 'sale-item-001',
      storeId: 'store-001',
      productId: productId,
      productSku: productSku,
      quantitySold: quantitySold,
      occurredAt: DateTime.utc(2026, 9, 5),
      performedBy: 'user-001',
      deviceId: 'device-001',
    );
  }

  Product product({
    ProductInventoryMode inventoryMode = ProductInventoryMode.direct,
    String? recipeId,
    double cost = 25,
    bool active = true,
    DateTime? deletedAt,
  }) {
    return Product(
      id: 'product-001',
      sku: 'SKU-001',
      productName: 'Test Product',
      cost: cost,
      retailPrice: 50,
      vat: 0,
      active: active,
      inventoryMode: inventoryMode,
      recipeId: recipeId,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
      deletedAt: deletedAt,
    );
  }

  Recipe recipe({
    String id = 'recipe-001',
    bool active = true,
    DateTime? deletedAt,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id,
      recipeCode: 'RCP-001',
      recipeName: 'Test Recipe',
      category: RecipeCategory.mainDish,
      yieldQuantity: 2,
      yieldUnitCode: 'EACH',
      active: active,
      ingredients: ingredients ??
          <RecipeIngredient>[
            const RecipeIngredient(
              id: 'line-001',
              recipeId: 'recipe-001',
              ingredientId: 'ingredient-001',
              ingredientSku: 'ING-001',
              ingredientName: 'Ingredient One',
              usageUnitCode: 'GRAM',
              quantityRequired: 100,
              costPerUsageUnit: 0.05,
            ),
            const RecipeIngredient(
              id: 'line-002',
              recipeId: 'recipe-001',
              ingredientId: 'ingredient-002',
              ingredientSku: 'ING-002',
              ingredientName: 'Ingredient Two',
              usageUnitCode: 'ML',
              quantityRequired: 50,
              costPerUsageUnit: 0.02,
            ),
          ],
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
      deletedAt: deletedAt,
    );
  }

  group('Sale Consumption Planner', () {
    test('creates DIRECT Product movement', () {
      final SaleConsumptionPlan plan = planner.createPlan(
        request: request(),
        product: product(),
      );

      expect(plan.inventoryMode, ProductInventoryMode.direct);
      expect(plan.movements, hasLength(1));
      expect(plan.movements.single.itemType, ConsumptionItemType.product);
      expect(plan.movements.single.quantityDelta, -4);
      expect(plan.movements.single.unitCode, 'EACH');
      expect(plan.expectedCost, 100);
      expect(plan.validate, returnsNormally);
    });

    test('creates RECIPE Ingredient movements', () {
      final SaleConsumptionPlan plan = planner.createPlan(
        request: request(),
        product: product(
          inventoryMode: ProductInventoryMode.recipe,
          recipeId: 'recipe-001',
        ),
        recipe: recipe(),
      );

      expect(plan.inventoryMode, ProductInventoryMode.recipe);
      expect(plan.movements, hasLength(2));

      expect(
        plan.movements[0].quantityDelta,
        -200,
      );

      expect(
        plan.movements[1].quantityDelta,
        -100,
      );

      expect(plan.movements[0].recipeId, 'recipe-001');
      expect(plan.movements[0].recipeIngredientId, 'line-001');
      expect(plan.expectedCost, 12);
      expect(plan.validate, returnsNormally);
    });

    test('creates NONE plan without movements', () {
      final SaleConsumptionPlan plan = planner.createPlan(
        request: request(),
        product: product(
          inventoryMode: ProductInventoryMode.none,
        ),
      );

      expect(plan.movements, isEmpty);
      expect(plan.expectedCost, 0);
      expect(plan.ignoresInventory, isTrue);
      expect(plan.validate, returnsNormally);
    });

    test('rejects mismatched Product ID', () {
      expect(
        () => planner.createPlan(
          request: request(
            productId: 'different-product',
          ),
          product: product(),
        ),
        throwsStateError,
      );
    });

    test('rejects mismatched Product SKU', () {
      expect(
        () => planner.createPlan(
          request: request(
            productSku: 'WRONG-SKU',
          ),
          product: product(),
        ),
        throwsStateError,
      );
    });

    test('requires Recipe for RECIPE Product', () {
      expect(
        () => planner.createPlan(
          request: request(),
          product: product(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects mismatched Recipe', () {
      expect(
        () => planner.createPlan(
          request: request(),
          product: product(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
          recipe: recipe(
            id: 'recipe-002',
          ),
        ),
        throwsStateError,
      );
    });

    test('rejects inactive Product', () {
      expect(
        () => planner.createPlan(
          request: request(),
          product: product(active: false),
        ),
        throwsStateError,
      );
    });

    test('rejects inactive Recipe', () {
      expect(
        () => planner.createPlan(
          request: request(),
          product: product(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
          recipe: recipe(active: false),
        ),
        throwsStateError,
      );
    });

    test('uses deterministic movement keys', () {
      final SaleConsumptionPlan first = planner.createPlan(
        request: request(),
        product: product(),
      );

      final SaleConsumptionPlan second = planner.createPlan(
        request: request(),
        product: product(),
      );

      expect(
        first.movements.single.idempotencyKey,
        second.movements.single.idempotencyKey,
      );

      expect(
        first.movements.single.idempotencyKey,
        'SALE:sale-001:sale-item-001:'
        'PRODUCT:product-001:CONSUME',
      );
    });

    test('keeps Recipe lines independently idempotent', () {
      final SaleConsumptionPlan plan = planner.createPlan(
        request: request(),
        product: product(
          inventoryMode: ProductInventoryMode.recipe,
          recipeId: 'recipe-001',
        ),
        recipe: recipe(),
      );

      expect(
        plan.movements
            .map(
              (PlannedInventoryMovement movement) => movement.idempotencyKey,
            )
            .toSet(),
        hasLength(2),
      );

      expect(
        plan.movements[0].idempotencyKey,
        contains('line-001'),
      );

      expect(
        plan.movements[1].idempotencyKey,
        contains('line-002'),
      );
    });
  });
}
