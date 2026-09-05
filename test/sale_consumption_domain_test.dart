import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';

void main() {
  SaleConsumptionRequest buildRequest({
    double quantitySold = 2,
  }) {
    return SaleConsumptionRequest(
      saleId: 'sale-001',
      saleItemId: 'sale-item-001',
      storeId: 'store-001',
      productId: 'product-001',
      productSku: 'SKU-001',
      quantitySold: quantitySold,
      occurredAt: DateTime.utc(
        2026,
        9,
        5,
      ),
      performedBy: 'user-001',
      deviceId: 'device-001',
    );
  }

  PlannedInventoryMovement buildProductMovement({
    ConsumptionOperation operation = ConsumptionOperation.consume,
    double quantityDelta = -2,
    String? reversalOfMovementId,
  }) {
    return PlannedInventoryMovement(
      idempotencyKey: 'SALE:sale-001:sale-item-001:'
          'PRODUCT:product-001:'
          '${operation.name}',
      operation: operation,
      itemType: ConsumptionItemType.product,
      itemId: 'product-001',
      itemCode: 'SKU-001',
      unitCode: 'EACH',
      quantityDelta: quantityDelta,
      unitCostSnapshot: 50,
      sourceSaleId: 'sale-001',
      sourceSaleItemId: 'sale-item-001',
      storeId: 'store-001',
      performedBy: 'user-001',
      deviceId: 'device-001',
      occurredAt: DateTime.utc(
        2026,
        9,
        5,
      ),
      reversalOfMovementId: reversalOfMovementId,
    );
  }

  PlannedInventoryMovement buildIngredientMovement({
    String ingredientId = 'ingredient-001',
    String ingredientCode = 'ING-001',
    String recipeIngredientId = 'recipe-line-001',
    double quantityDelta = -0.5,
    double unitCost = 20,
  }) {
    return PlannedInventoryMovement(
      idempotencyKey: 'SALE:sale-001:sale-item-001:'
          'INGREDIENT:$ingredientId',
      operation: ConsumptionOperation.consume,
      itemType: ConsumptionItemType.ingredient,
      itemId: ingredientId,
      itemCode: ingredientCode,
      unitCode: 'KG',
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCost,
      sourceSaleId: 'sale-001',
      sourceSaleItemId: 'sale-item-001',
      storeId: 'store-001',
      performedBy: 'user-001',
      deviceId: 'device-001',
      occurredAt: DateTime.utc(
        2026,
        9,
        5,
      ),
      recipeId: 'recipe-001',
      recipeIngredientId: recipeIngredientId,
    );
  }

  group('Sale Consumption Request', () {
    test('accepts a valid request', () {
      final SaleConsumptionRequest request = buildRequest();

      expect(
        request.validate,
        returnsNormally,
      );

      expect(
        request.idempotencyKey,
        'SALE:sale-001:'
        'sale-item-001:CONSUME',
      );
    });

    test('rejects zero quantity', () {
      expect(
        () => buildRequest(
          quantitySold: 0,
        ).validate(),
        throwsFormatException,
      );
    });

    test('rejects negative quantity', () {
      expect(
        () => buildRequest(
          quantitySold: -1,
        ).validate(),
        throwsFormatException,
      );
    });
  });

  group('Planned Inventory Movement', () {
    test('accepts Product consumption', () {
      final PlannedInventoryMovement movement = buildProductMovement();

      expect(
        movement.validate,
        returnsNormally,
      );

      expect(
        movement.isProductMovement,
        isTrue,
      );

      expect(
        movement.totalCostSnapshot,
        100,
      );
    });

    test(
      'accepts Ingredient consumption',
      () {
        final PlannedInventoryMovement movement = buildIngredientMovement();

        expect(
          movement.validate,
          returnsNormally,
        );

        expect(
          movement.isIngredientMovement,
          isTrue,
        );

        expect(
          movement.totalCostSnapshot,
          10,
        );
      },
    );

    test(
      'rejects positive consumption quantity',
      () {
        expect(
          () => buildProductMovement(
            quantityDelta: 2,
          ).validate(),
          throwsFormatException,
        );
      },
    );

    test(
      'requires Recipe references '
      'for Ingredient movement',
      () {
        final PlannedInventoryMovement movement = PlannedInventoryMovement(
          idempotencyKey: 'sale-001:ingredient-001',
          operation: ConsumptionOperation.consume,
          itemType: ConsumptionItemType.ingredient,
          itemId: 'ingredient-001',
          itemCode: 'ING-001',
          unitCode: 'KG',
          quantityDelta: -1,
          unitCostSnapshot: 10,
          sourceSaleId: 'sale-001',
          sourceSaleItemId: 'sale-item-001',
          storeId: 'store-001',
          performedBy: 'user-001',
          deviceId: 'device-001',
          occurredAt: DateTime.utc(
            2026,
            9,
            5,
          ),
        );

        expect(
          movement.validate,
          throwsFormatException,
        );
      },
    );

    test(
      'requires original movement '
      'for restoration',
      () {
        expect(
          () => buildProductMovement(
            operation: ConsumptionOperation.restore,
            quantityDelta: 2,
          ).validate(),
          throwsFormatException,
        );
      },
    );

    test('accepts valid restoration', () {
      final PlannedInventoryMovement movement = buildProductMovement(
        operation: ConsumptionOperation.restore,
        quantityDelta: 2,
        reversalOfMovementId: 'movement-001',
      );

      expect(
        movement.validate,
        returnsNormally,
      );

      expect(
        movement.isRestoration,
        isTrue,
      );
    });
  });

  group('Sale Consumption Plan', () {
    test(
      'accepts DIRECT Product plan',
      () {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.direct,
          movements: <PlannedInventoryMovement>[
            buildProductMovement(),
          ],
          expectedCost: 100,
        );

        expect(
          plan.validate,
          returnsNormally,
        );

        expect(
          plan.usesDirectInventory,
          isTrue,
        );

        expect(plan.movementCount, 1);
      },
    );

    test(
      'accepts RECIPE Product plan',
      () {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.recipe,
          movements: <PlannedInventoryMovement>[
            buildIngredientMovement(),
            buildIngredientMovement(
              ingredientId: 'ingredient-002',
              ingredientCode: 'ING-002',
              recipeIngredientId: 'recipe-line-002',
              quantityDelta: -1,
              unitCost: 5,
            ),
          ],
          expectedCost: 15,
        );

        expect(
          plan.validate,
          returnsNormally,
        );

        expect(
          plan.usesRecipeInventory,
          isTrue,
        );

        expect(plan.movementCount, 2);
      },
    );

    test(
      'accepts NONE Product plan',
      () {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.none,
          movements: const <PlannedInventoryMovement>[],
          expectedCost: 0,
        );

        expect(
          plan.validate,
          returnsNormally,
        );

        expect(
          plan.ignoresInventory,
          isTrue,
        );

        expect(
          plan.affectsInventory,
          isFalse,
        );
      },
    );

    test(
      'rejects Product movement '
      'for RECIPE mode',
      () {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.recipe,
          movements: <PlannedInventoryMovement>[
            buildProductMovement(),
          ],
          expectedCost: 100,
        );

        expect(
          plan.validate,
          throwsFormatException,
        );
      },
    );

    test(
      'rejects movement for NONE mode',
      () {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.none,
          movements: <PlannedInventoryMovement>[
            buildProductMovement(),
          ],
          expectedCost: 100,
        );

        expect(
          plan.validate,
          throwsFormatException,
        );
      },
    );

    test(
      'rejects duplicate idempotency keys',
      () {
        final PlannedInventoryMovement movement = buildIngredientMovement();

        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.recipe,
          movements: <PlannedInventoryMovement>[
            movement,
            movement,
          ],
          expectedCost: 20,
        );

        expect(
          plan.validate,
          throwsFormatException,
        );
      },
    );

    test(
      'rejects incorrect expected cost',
      () {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.direct,
          movements: <PlannedInventoryMovement>[
            buildProductMovement(),
          ],
          expectedCost: 99,
        );

        expect(
          plan.validate,
          throwsFormatException,
        );
      },
    );

    test(
      'rejects mismatched Sale ID',
      () {
        final PlannedInventoryMovement movement = PlannedInventoryMovement(
          idempotencyKey: 'invalid-sale-movement',
          operation: ConsumptionOperation.consume,
          itemType: ConsumptionItemType.product,
          itemId: 'product-001',
          itemCode: 'SKU-001',
          unitCode: 'EACH',
          quantityDelta: -2,
          unitCostSnapshot: 50,
          sourceSaleId: 'different-sale',
          sourceSaleItemId: 'sale-item-001',
          storeId: 'store-001',
          performedBy: 'user-001',
          deviceId: 'device-001',
          occurredAt: DateTime.utc(
            2026,
            9,
            5,
          ),
        );

        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: buildRequest(),
          inventoryMode: ProductInventoryMode.direct,
          movements: <PlannedInventoryMovement>[
            movement,
          ],
          expectedCost: 100,
        );

        expect(
          plan.validate,
          throwsFormatException,
        );
      },
    );
  });

  group('Sale Consumption storage values', () {
    test('stores item types', () {
      expect(
        consumptionItemTypeToStorage(
          ConsumptionItemType.product,
        ),
        'PRODUCT',
      );

      expect(
        consumptionItemTypeFromStorage(
          'ingredient',
        ),
        ConsumptionItemType.ingredient,
      );
    });

    test('stores operations', () {
      expect(
        consumptionOperationToStorage(
          ConsumptionOperation.consume,
        ),
        'CONSUME',
      );

      expect(
        consumptionOperationFromStorage(
          'restore',
        ),
        ConsumptionOperation.restore,
      );
    });
  });
}
