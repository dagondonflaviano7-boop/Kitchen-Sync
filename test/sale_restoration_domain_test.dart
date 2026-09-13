import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/models/sale_restoration.dart';

void main() {
  SaleRestorationRequest request({
    SaleRestorationOperation operation = SaleRestorationOperation.voidSale,
    String restorationId = 'restoration-001',
    String originalSaleId = 'sale-001',
    String reason = 'Customer transaction voided',
  }) {
    return SaleRestorationRequest(
      restorationId: restorationId,
      restorationTransactionNumber: 'RESTORE-0001',
      originalSaleId: originalSaleId,
      operation: operation,
      reason: reason,
      performedBy: 'user-001',
      deviceId: 'device-001',
      occurredAt: DateTime.utc(2026, 9, 13, 10),
    );
  }

  SaleRestorationItemPlan item({
    String restorationItemId = 'restoration-item-001',
    String originalSaleItemId = 'sale-item-001',
    double quantity = 2,
    double unitCost = 25,
    double cogs = 50,
  }) {
    return SaleRestorationItemPlan(
      restorationItemId: restorationItemId,
      originalSaleItemId: originalSaleItemId,
      productId: 'product-001',
      productSku: 'SKU-001',
      productName: 'Test Product',
      quantity: quantity,
      sellingPrice: 100,
      discount: 20,
      netAmount: 180,
      unitCost: unitCost,
      cogs: cogs,
      recipeVersion: null,
      ingredientCostJson: null,
    );
  }

  SaleRestorationMovementPlan productMovement({
    String restorationMovementId = 'restore-movement-001',
    String restorationId = 'restoration-001',
    String originalMovementId = 'movement-001',
    String? reversalOfMovementId,
    String originalSaleId = 'sale-001',
    String originalSaleItemId = 'sale-item-001',
    String storeId = 'store-001',
    double quantityDelta = 2,
    double unitCostSnapshot = 25,
    String? recipeId,
    String? recipeIngredientId,
  }) {
    return SaleRestorationMovementPlan(
      restorationMovementId: restorationMovementId,
      restorationId: restorationId,
      originalMovementId: originalMovementId,
      reversalOfMovementId: reversalOfMovementId ?? originalMovementId,
      itemType: ConsumptionItemType.product,
      itemId: 'product-001',
      itemCode: 'SKU-001',
      unitCode: 'EACH',
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCostSnapshot,
      originalSaleId: originalSaleId,
      originalSaleItemId: originalSaleItemId,
      storeId: storeId,
      recipeId: recipeId,
      recipeIngredientId: recipeIngredientId,
    );
  }

  SaleRestorationMovementPlan ingredientMovement({
    String originalMovementId = 'ingredient-movement-001',
    String? reversalOfMovementId,
    String originalSaleItemId = 'sale-item-001',
    String? recipeId = 'recipe-001',
    String? recipeIngredientId = 'recipe-line-001',
    double quantityDelta = 100,
    double unitCostSnapshot = 0.05,
  }) {
    return SaleRestorationMovementPlan(
      restorationMovementId: 'restore-ingredient-001',
      restorationId: 'restoration-001',
      originalMovementId: originalMovementId,
      reversalOfMovementId: reversalOfMovementId ?? originalMovementId,
      itemType: ConsumptionItemType.ingredient,
      itemId: 'ingredient-001',
      itemCode: 'ING-001',
      unitCode: 'GRAM',
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCostSnapshot,
      originalSaleId: 'sale-001',
      originalSaleItemId: originalSaleItemId,
      storeId: 'store-001',
      recipeId: recipeId,
      recipeIngredientId: recipeIngredientId,
    );
  }

  SaleRestorationPlan plan({
    SaleRestorationRequest? restorationRequest,
    List<SaleRestorationItemPlan>? items,
    List<SaleRestorationMovementPlan>? movements,
    double subtotalReversal = -200,
    double netSalesReversal = -180,
    double cogsReversal = -50,
    double grossProfitReversal = -130,
    double grossMarginSnapshot = 72.222222,
  }) {
    return SaleRestorationPlan(
      request: restorationRequest ?? request(),
      originalTransactionNumber: 'TXN-0001',
      storeId: 'store-001',
      items: items ?? <SaleRestorationItemPlan>[item()],
      movements: movements ??
          <SaleRestorationMovementPlan>[
            productMovement(),
          ],
      subtotalReversal: subtotalReversal,
      discountReversal: -20,
      netSalesReversal: netSalesReversal,
      costReversal: cogsReversal,
      cogsReversal: cogsReversal,
      grossProfitReversal: grossProfitReversal,
      grossMarginSnapshot: grossMarginSnapshot,
    );
  }

  group('Restoration operation mapping', () {
    test('maps VOID and REFUND values', () {
      expect(
        saleRestorationOperationToStorage(
          SaleRestorationOperation.voidSale,
        ),
        'VOID',
      );

      expect(
        saleRestorationOperationToStorage(
          SaleRestorationOperation.refund,
        ),
        'REFUND',
      );

      expect(
        saleRestorationOperationFromStorage(' void '),
        SaleRestorationOperation.voidSale,
      );

      expect(
        saleRestorationOperationFromStorage('refund'),
        SaleRestorationOperation.refund,
      );
    });

    test('rejects unsupported operation', () {
      expect(
        () => saleRestorationOperationFromStorage('CANCEL'),
        throwsFormatException,
      );
    });
  });

  group('Restoration request', () {
    test('builds deterministic VOID and REFUND keys', () {
      final SaleRestorationRequest voidRequest = request();

      final SaleRestorationRequest refundRequest = request(
        operation: SaleRestorationOperation.refund,
      );

      expect(voidRequest.validate, returnsNormally);
      expect(voidRequest.idempotencyKey, 'RESTORE:VOID:sale-001');

      expect(refundRequest.validate, returnsNormally);
      expect(
        refundRequest.idempotencyKey,
        'RESTORE:REFUND:sale-001',
      );
    });

    test('rejects invalid request values', () {
      expect(
        request(reason: ' ').validate,
        throwsFormatException,
      );

      expect(
        request(
          restorationId: 'sale-001',
        ).validate,
        throwsFormatException,
      );
    });
  });

  group('Historical Item costing', () {
    test('preserves Item unit cost and COGS', () {
      final SaleRestorationItemPlan restorationItem = item();

      expect(restorationItem.validate, returnsNormally);
      expect(restorationItem.unitCost, 25);
      expect(restorationItem.cogs, 50);
    });

    test('rejects invalid Item quantity and cost', () {
      expect(
        item(quantity: 0).validate,
        throwsFormatException,
      );

      expect(
        item(unitCost: -1).validate,
        throwsFormatException,
      );
    });
  });

  group('Restoration movements', () {
    test('validates inverse Product movement', () {
      final SaleRestorationMovementPlan movement = productMovement();

      expect(movement.validate, returnsNormally);
      expect(movement.restoresProduct, isTrue);
      expect(movement.restoresIngredient, isFalse);
      expect(movement.quantityDelta, 2);
      expect(movement.unitCostSnapshot, 25);
      expect(movement.totalCostSnapshot, 50);
      expect(
        movement.idempotencyKey,
        'RESTORE:restoration-001:movement-001',
      );
    });

    test('validates Ingredient movement lineage', () {
      final SaleRestorationMovementPlan movement = ingredientMovement();

      expect(movement.validate, returnsNormally);
      expect(movement.restoresIngredient, isTrue);
      expect(movement.quantityDelta, 100);
      expect(movement.unitCostSnapshot, 0.05);
      expect(movement.totalCostSnapshot, 5);
      expect(movement.recipeId, 'recipe-001');
      expect(
        movement.recipeIngredientId,
        'recipe-line-001',
      );
    });

    test('rejects invalid original movement linkage', () {
      expect(
        productMovement(
          reversalOfMovementId: 'movement-002',
        ).validate,
        throwsFormatException,
      );
    });

    test('rejects non-positive or non-finite values', () {
      expect(
        productMovement(quantityDelta: 0).validate,
        throwsFormatException,
      );

      expect(
        productMovement(quantityDelta: -2).validate,
        throwsFormatException,
      );

      expect(
        productMovement(
          unitCostSnapshot: double.infinity,
        ).validate,
        throwsFormatException,
      );
    });

    test('enforces Recipe lineage rules', () {
      expect(
        ingredientMovement(recipeId: ' ').validate,
        throwsFormatException,
      );

      expect(
        ingredientMovement(
          recipeIngredientId: ' ',
        ).validate,
        throwsFormatException,
      );

      expect(
        productMovement(
          recipeId: 'recipe-001',
          recipeIngredientId: 'recipe-line-001',
        ).validate,
        throwsFormatException,
      );
    });
  });

  group('Restoration plan', () {
    test('validates signed financial reversal', () {
      final SaleRestorationPlan restorationPlan = plan();

      expect(restorationPlan.validate, returnsNormally);
      expect(restorationPlan.subtotalReversal, -200);
      expect(restorationPlan.netSalesReversal, -180);
      expect(restorationPlan.cogsReversal, -50);
      expect(restorationPlan.grossProfitReversal, -130);
      expect(restorationPlan.grossMarginSnapshot, 72.222222);
    });

    test('protects immutable collections', () {
      final SaleRestorationPlan restorationPlan = plan();

      expect(
        () => restorationPlan.items.clear(),
        throwsUnsupportedError,
      );

      expect(
        () => restorationPlan.movements.clear(),
        throwsUnsupportedError,
      );
    });

    test('supports normalized lookups', () {
      final SaleRestorationPlan restorationPlan = plan();

      expect(
        restorationPlan.itemForOriginalSaleItem(' sale-item-001 ').productId,
        'product-001',
      );

      expect(
        restorationPlan.movementForOriginalMovement(' movement-001 ').itemId,
        'product-001',
      );

      expect(
        () => restorationPlan.itemForOriginalSaleItem(
          'missing-item',
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate Item and movement records', () {
      expect(
        plan(
          items: <SaleRestorationItemPlan>[
            item(),
            item(
              restorationItemId: 'restoration-item-002',
            ),
          ],
        ).validate,
        throwsFormatException,
      );

      expect(
        plan(
          movements: <SaleRestorationMovementPlan>[
            productMovement(),
            productMovement(
              restorationMovementId: 'restore-movement-002',
            ),
          ],
        ).validate,
        throwsFormatException,
      );
    });

    test('rejects ownership mismatches', () {
      expect(
        plan(
          movements: <SaleRestorationMovementPlan>[
            productMovement(
              restorationId: 'restoration-002',
            ),
          ],
        ).validate,
        throwsFormatException,
      );

      expect(
        plan(
          movements: <SaleRestorationMovementPlan>[
            productMovement(
              originalSaleId: 'sale-002',
            ),
          ],
        ).validate,
        throwsFormatException,
      );

      expect(
        plan(
          movements: <SaleRestorationMovementPlan>[
            productMovement(
              storeId: 'store-002',
            ),
          ],
        ).validate,
        throwsFormatException,
      );
    });

    test('rejects invalid financial values', () {
      expect(
        plan(netSalesReversal: 180).validate,
        throwsFormatException,
      );

      expect(
        plan(cogsReversal: double.nan).validate,
        throwsFormatException,
      );

      expect(
        plan(
          grossMarginSnapshot: double.infinity,
        ).validate,
        throwsFormatException,
      );
    });

    test('supports Product and Ingredient restoration together', () {
      final SaleRestorationPlan restorationPlan = plan(
        items: <SaleRestorationItemPlan>[
          item(),
          item(
            restorationItemId: 'restoration-item-002',
            originalSaleItemId: 'sale-item-002',
          ),
        ],
        movements: <SaleRestorationMovementPlan>[
          productMovement(),
          ingredientMovement(
            originalSaleItemId: 'sale-item-002',
          ),
        ],
      );

      expect(restorationPlan.validate, returnsNormally);
      expect(restorationPlan.items, hasLength(2));
      expect(restorationPlan.movements, hasLength(2));
    });
  });
}
