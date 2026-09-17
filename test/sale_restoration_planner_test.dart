import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/models/sale_restoration.dart';
import 'package:kitchen_sync/domain/services/sale_restoration_planner.dart';

void main() {
  const SaleRestorationPlanner planner = SaleRestorationPlanner();

  SaleRestorationRequest request({
    String restorationId = 'restoration-001',
    String originalSaleId = 'sale-001',
    SaleRestorationOperation operation = SaleRestorationOperation.voidSale,
  }) {
    return SaleRestorationRequest(
      restorationId: restorationId,
      restorationTransactionNumber: 'VOID-0001',
      originalSaleId: originalSaleId,
      operation: operation,
      reason: 'Customer transaction voided',
      performedBy: 'user-001',
      deviceId: 'device-001',
      occurredAt: DateTime.utc(2026, 9, 17, 8),
    );
  }

  HistoricalSaleItemSnapshot item({
    String saleItemId = 'sale-item-001',
    String saleId = 'sale-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    String productName = 'Direct Product',
    double quantity = 2,
    double sellingPrice = 100,
    double discount = 20,
    double netAmount = 180,
    double unitCost = 25,
    double cogs = 50,
    int? recipeVersion,
    String? ingredientCostJson,
  }) {
    return HistoricalSaleItemSnapshot(
      saleItemId: saleItemId,
      saleId: saleId,
      productId: productId,
      productSku: productSku,
      productName: productName,
      quantity: quantity,
      sellingPrice: sellingPrice,
      discount: discount,
      netAmount: netAmount,
      unitCost: unitCost,
      cogs: cogs,
      recipeVersion: recipeVersion,
      ingredientCostJson: ingredientCostJson,
    );
  }

  HistoricalSaleSnapshot sale({
    String saleId = 'sale-001',
    String storeId = 'store-001',
    String status = 'COMPLETED',
    List<HistoricalSaleItemSnapshot>? items,
    double subtotal = 200,
    double discount = 20,
    double netSales = 180,
    double cost = 50,
    double cogs = 50,
    double grossProfit = 130,
    double grossMargin = 72.222222,
  }) {
    return HistoricalSaleSnapshot(
      saleId: saleId,
      transactionNumber: 'TXN-0001',
      storeId: storeId,
      status: status,
      subtotal: subtotal,
      discount: discount,
      netSales: netSales,
      cost: cost,
      cogs: cogs,
      grossProfit: grossProfit,
      grossMargin: grossMargin,
      items: items ?? <HistoricalSaleItemSnapshot>[item()],
    );
  }

  HistoricalSaleMovementSnapshot productMovement({
    String movementId = 'movement-product-001',
    String sourceSaleId = 'sale-001',
    String sourceSaleItemId = 'sale-item-001',
    String storeId = 'store-001',
    double quantityDelta = -2,
    double unitCostSnapshot = 25,
    String? reversalOfMovementId,
  }) {
    return HistoricalSaleMovementSnapshot(
      movementId: movementId,
      itemType: ConsumptionItemType.product,
      itemId: 'product-001',
      itemCode: 'SKU-001',
      unitCode: 'EACH',
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCostSnapshot,
      sourceSaleId: sourceSaleId,
      sourceSaleItemId: sourceSaleItemId,
      storeId: storeId,
      reversalOfMovementId: reversalOfMovementId,
    );
  }

  HistoricalSaleMovementSnapshot ingredientMovement({
    String movementId = 'movement-ingredient-001',
    String sourceSaleId = 'sale-001',
    String sourceSaleItemId = 'sale-item-001',
    String storeId = 'store-001',
    double quantityDelta = -100,
    double unitCostSnapshot = 0.5,
    String? recipeId = 'recipe-001',
    String? recipeIngredientId = 'recipe-line-001',
  }) {
    return HistoricalSaleMovementSnapshot(
      movementId: movementId,
      itemType: ConsumptionItemType.ingredient,
      itemId: 'ingredient-001',
      itemCode: 'ING-001',
      unitCode: 'GRAM',
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCostSnapshot,
      sourceSaleId: sourceSaleId,
      sourceSaleItemId: sourceSaleItemId,
      storeId: storeId,
      recipeId: recipeId,
      recipeIngredientId: recipeIngredientId,
    );
  }

  group('Sale Restoration Planner behavior', () {
    test('creates DIRECT Product restoration', () {
      final SaleRestorationPlan plan = planner.createPlan(
        request: request(),
        sale: sale(),
        movements: <HistoricalSaleMovementSnapshot>[
          productMovement(),
        ],
      );

      expect(plan.validate, returnsNormally);
      expect(plan.items, hasLength(1));
      expect(plan.movements, hasLength(1));

      final SaleRestorationItemPlan restoredItem = plan.items.single;

      final SaleRestorationMovementPlan movement = plan.movements.single;

      expect(restoredItem.unitCost, 25);
      expect(restoredItem.cogs, 50);
      expect(movement.restoresProduct, isTrue);
      expect(movement.quantityDelta, 2);
      expect(movement.unitCostSnapshot, 25);
      expect(movement.totalCostSnapshot, 50);
      expect(
        movement.originalMovementId,
        'movement-product-001',
      );
      expect(
        movement.reversalOfMovementId,
        'movement-product-001',
      );
    });

    test('creates RECIPE Ingredient restoration', () {
      final HistoricalSaleItemSnapshot recipeItem = item(
        unitCost: 25,
        cogs: 50,
        recipeVersion: 3,
        ingredientCostJson: '{"historical":true}',
      );

      final SaleRestorationPlan plan = planner.createPlan(
        request: request(),
        sale: sale(
          items: <HistoricalSaleItemSnapshot>[
            recipeItem,
          ],
        ),
        movements: <HistoricalSaleMovementSnapshot>[
          ingredientMovement(),
        ],
      );

      final SaleRestorationMovementPlan movement = plan.movements.single;

      expect(plan.validate, returnsNormally);
      expect(movement.restoresIngredient, isTrue);
      expect(movement.quantityDelta, 100);
      expect(movement.unitCostSnapshot, 0.5);
      expect(movement.totalCostSnapshot, 50);
      expect(movement.recipeId, 'recipe-001');
      expect(
        movement.recipeIngredientId,
        'recipe-line-001',
      );
      expect(plan.items.single.recipeVersion, 3);
      expect(
        plan.items.single.ingredientCostJson,
        '{"historical":true}',
      );
    });

    test('supports zero-cost NONE Item without movement', () {
      final HistoricalSaleItemSnapshot noneItem = item(
        unitCost: 0,
        cogs: 0,
      );

      final SaleRestorationPlan plan = planner.createPlan(
        request: request(),
        sale: sale(
          items: <HistoricalSaleItemSnapshot>[
            noneItem,
          ],
          cost: 0,
          cogs: 0,
          grossProfit: 180,
          grossMargin: 100,
        ),
        movements: const <HistoricalSaleMovementSnapshot>[],
      );

      expect(plan.validate, returnsNormally);
      expect(plan.items, hasLength(1));
      expect(plan.movements, isEmpty);
      expect(plan.items.single.unitCost, 0);
      expect(plan.items.single.cogs, 0);
    });

    test('creates signed financial reversals', () {
      final SaleRestorationPlan plan = planner.createPlan(
        request: request(),
        sale: sale(),
        movements: <HistoricalSaleMovementSnapshot>[
          productMovement(),
        ],
      );

      expect(plan.subtotalReversal, -200);
      expect(plan.discountReversal, -20);
      expect(plan.netSalesReversal, -180);
      expect(plan.costReversal, -50);
      expect(plan.cogsReversal, -50);
      expect(plan.grossProfitReversal, -130);
      expect(plan.grossMarginSnapshot, 72.222222);
    });

    test('generates deterministic Restoration IDs', () {
      final SaleRestorationPlan first = planner.createPlan(
        request: request(),
        sale: sale(),
        movements: <HistoricalSaleMovementSnapshot>[
          productMovement(),
        ],
      );

      final SaleRestorationPlan second = planner.createPlan(
        request: request(),
        sale: sale(),
        movements: <HistoricalSaleMovementSnapshot>[
          productMovement(),
        ],
      );

      expect(
        first.items.single.restorationItemId,
        'restoration-001:ITEM:sale-item-001',
      );

      expect(
        first.movements.single.restorationMovementId,
        'restoration-001:MOVEMENT:movement-product-001',
      );

      expect(
        first.items.single.restorationItemId,
        second.items.single.restorationItemId,
      );

      expect(
        first.movements.single.restorationMovementId,
        second.movements.single.restorationMovementId,
      );
    });

    test('rejects non-completed Sale', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(status: 'VOIDED'),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects request for another Sale', () {
      expect(
        () => planner.createPlan(
          request: request(
            originalSaleId: 'sale-002',
          ),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects movement ownership mismatches', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(
              sourceSaleId: 'sale-002',
            ),
          ],
        ),
        throwsFormatException,
      );

      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(
              sourceSaleItemId: 'sale-item-002',
            ),
          ],
        ),
        throwsFormatException,
      );

      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(
              storeId: 'store-002',
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate historical movements', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(),
            productMovement(),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects previously restored movement', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(
              reversalOfMovementId: 'restoration-movement-existing',
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects missing tracked movement', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: const <HistoricalSaleMovementSnapshot>[],
        ),
        throwsFormatException,
      );
    });

    test('rejects historical COGS mismatch', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(
              unitCostSnapshot: 20,
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('accepts historical COGS within tolerance', () {
      final SaleRestorationPlan plan = planner.createPlan(
        request: request(),
        sale: sale(
          items: <HistoricalSaleItemSnapshot>[
            item(
              cogs: 50.0000005,
            ),
          ],
          cogs: 50.0000005,
          cost: 50.0000005,
          grossProfit: 129.9999995,
        ),
        movements: <HistoricalSaleMovementSnapshot>[
          productMovement(),
        ],
      );

      expect(plan.validate, returnsNormally);
    });

    test('rejects invalid movement direction', () {
      expect(
        () => planner.createPlan(
          request: request(),
          sale: sale(),
          movements: <HistoricalSaleMovementSnapshot>[
            productMovement(
              quantityDelta: 2,
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('protects immutable output collections', () {
      final SaleRestorationPlan plan = planner.createPlan(
        request: request(),
        sale: sale(),
        movements: <HistoricalSaleMovementSnapshot>[
          productMovement(),
        ],
      );

      expect(
        () => plan.items.clear(),
        throwsUnsupportedError,
      );

      expect(
        () => plan.movements.clear(),
        throwsUnsupportedError,
      );
    });
  });
}
