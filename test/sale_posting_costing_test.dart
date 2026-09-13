import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/models/sale_posting.dart';
import 'package:kitchen_sync/domain/models/sale_posting_costing.dart';

void main() {
  const SalePostingCostingPlanner planner = SalePostingCostingPlanner();

  SalePostingItem item({
    String id = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    String productName = 'Test Product',
    double quantity = 2,
    double sellingPrice = 100,
    double discount = 20,
  }) {
    return SalePostingItem(
      id: id,
      productId: productId,
      productSku: productSku,
      productName: productName,
      quantity: quantity,
      sellingPrice: sellingPrice,
      discount: discount,
    );
  }

  SalePostingPayment payment({
    String id = 'payment-001',
    double amount = 180,
  }) {
    return SalePostingPayment(
      id: id,
      paymentType: 'CASH',
      amount: amount,
      createdAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
    );
  }

  SalePostingRequest request({
    String saleId = 'sale-001',
    List<SalePostingItem>? items,
    List<SalePostingPayment>? payments,
  }) {
    return SalePostingRequest(
      saleId: saleId,
      transactionNumber: 'TXN-0001',
      storeId: 'store-001',
      deviceId: 'device-001',
      cashierId: 'user-001',
      occurredAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
      items: items ??
          <SalePostingItem>[
            item(),
          ],
      payments: payments ??
          <SalePostingPayment>[
            payment(),
          ],
    );
  }

  SaleConsumptionRequest consumptionRequest({
    String saleId = 'sale-001',
    String saleItemId = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    double quantitySold = 2,
  }) {
    return SaleConsumptionRequest(
      saleId: saleId,
      saleItemId: saleItemId,
      storeId: 'store-001',
      productId: productId,
      productSku: productSku,
      quantitySold: quantitySold,
      occurredAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
      performedBy: 'user-001',
      deviceId: 'device-001',
    );
  }

  PlannedInventoryMovement productMovement({
    String saleId = 'sale-001',
    String saleItemId = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    double quantityDelta = -2,
    double unitCost = 25,
  }) {
    return PlannedInventoryMovement(
      idempotencyKey: 'SALE:$saleId:$saleItemId:'
          'PRODUCT:$productId:CONSUME',
      operation: ConsumptionOperation.consume,
      itemType: ConsumptionItemType.product,
      itemId: productId,
      itemCode: productSku,
      unitCode: 'EACH',
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCost,
      sourceSaleId: saleId,
      sourceSaleItemId: saleItemId,
      storeId: 'store-001',
      performedBy: 'user-001',
      deviceId: 'device-001',
      occurredAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
    );
  }

  PlannedInventoryMovement ingredientMovement({
    String saleId = 'sale-001',
    String saleItemId = 'sale-item-001',
    String ingredientId = 'ingredient-001',
    String ingredientCode = 'ING-001',
    String recipeIngredientId = 'recipe-line-001',
    String unitCode = 'GRAM',
    double quantityDelta = -100,
    double unitCost = 0.05,
  }) {
    return PlannedInventoryMovement(
      idempotencyKey: 'SALE:$saleId:$saleItemId:'
          'INGREDIENT:$ingredientId:'
          '$recipeIngredientId:CONSUME',
      operation: ConsumptionOperation.consume,
      itemType: ConsumptionItemType.ingredient,
      itemId: ingredientId,
      itemCode: ingredientCode,
      unitCode: unitCode,
      quantityDelta: quantityDelta,
      unitCostSnapshot: unitCost,
      sourceSaleId: saleId,
      sourceSaleItemId: saleItemId,
      storeId: 'store-001',
      performedBy: 'user-001',
      deviceId: 'device-001',
      occurredAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
      recipeId: 'recipe-001',
      recipeIngredientId: recipeIngredientId,
    );
  }

  SaleConsumptionPlan directPlan({
    String saleId = 'sale-001',
    String saleItemId = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    double quantity = 2,
    double unitCost = 25,
  }) {
    return SaleConsumptionPlan(
      request: consumptionRequest(
        saleId: saleId,
        saleItemId: saleItemId,
        productId: productId,
        productSku: productSku,
        quantitySold: quantity,
      ),
      inventoryMode: ProductInventoryMode.direct,
      movements: <PlannedInventoryMovement>[
        productMovement(
          saleId: saleId,
          saleItemId: saleItemId,
          productId: productId,
          productSku: productSku,
          quantityDelta: -quantity,
          unitCost: unitCost,
        ),
      ],
      expectedCost: quantity * unitCost,
    );
  }

  SaleConsumptionPlan recipePlan({
    List<PlannedInventoryMovement>? movements,
    double expectedCost = 5,
  }) {
    return SaleConsumptionPlan(
      request: consumptionRequest(),
      inventoryMode: ProductInventoryMode.recipe,
      movements: movements ??
          <PlannedInventoryMovement>[
            ingredientMovement(),
          ],
      expectedCost: expectedCost,
    );
  }

  SaleConsumptionPlan nonePlan({
    String saleItemId = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    double quantity = 2,
  }) {
    return SaleConsumptionPlan(
      request: consumptionRequest(
        saleItemId: saleItemId,
        productId: productId,
        productSku: productSku,
        quantitySold: quantity,
      ),
      inventoryMode: ProductInventoryMode.none,
      movements: const <PlannedInventoryMovement>[],
      expectedCost: 0,
    );
  }

  group('DIRECT Sale Posting costing', () {
    test('uses expected plan cost as COGS', () {
      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: request(),
        plans: <SaleConsumptionPlan>[
          directPlan(),
        ],
      );

      final SalePostingItemCostSnapshot cost = snapshot.items.single;

      expect(cost.inventoryMode, ProductInventoryMode.direct);
      expect(cost.quantity, 2);
      expect(cost.netAmount, 180);
      expect(cost.unitCost, 25);
      expect(cost.cogs, 50);
      expect(cost.grossProfit, 130);
      expect(cost.grossMargin, closeTo(72.222222, 0.0001));
      expect(cost.recipeId, isNull);
      expect(cost.recipeVersion, isNull);
      expect(cost.ingredientCostJson, isNull);

      expect(snapshot.totalCost, 50);
      expect(snapshot.totalCogs, 50);
      expect(snapshot.grossProfit, 130);
      expect(
        snapshot.grossMargin,
        closeTo(72.222222, 0.0001),
      );
      expect(snapshot.validate, returnsNormally);
    });

    test('allows negative gross profit', () {
      final SalePostingRequest lossRequest = request(
        items: <SalePostingItem>[
          item(
            quantity: 1,
            sellingPrice: 20,
            discount: 0,
          ),
        ],
        payments: <SalePostingPayment>[
          payment(amount: 20),
        ],
      );

      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: lossRequest,
        plans: <SaleConsumptionPlan>[
          directPlan(
            quantity: 1,
            unitCost: 25,
          ),
        ],
      );

      expect(snapshot.totalCogs, 25);
      expect(snapshot.grossProfit, -5);
      expect(snapshot.grossMargin, -25);
      expect(snapshot.validate, returnsNormally);
    });
  });

  group('RECIPE Sale Posting costing', () {
    test('uses Ingredient movement cost and lineage', () {
      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: request(),
        plans: <SaleConsumptionPlan>[
          recipePlan(),
        ],
      );

      final SalePostingItemCostSnapshot cost = snapshot.items.single;

      expect(cost.inventoryMode, ProductInventoryMode.recipe);
      expect(cost.unitCost, 2.5);
      expect(cost.cogs, 5);
      expect(cost.grossProfit, 175);
      expect(cost.recipeId, 'recipe-001');
      expect(cost.recipeVersion, isNull);
      expect(cost.ingredientCostJson, isNotNull);

      final Map<String, dynamic> json =
          jsonDecode(cost.ingredientCostJson!) as Map<String, dynamic>;

      expect(json['recipeId'], 'recipe-001');
      expect(json['totalIngredientCost'], 5);

      final List<dynamic> ingredients = json['ingredients'] as List<dynamic>;

      expect(ingredients, hasLength(1));

      final Map<String, dynamic> ingredient =
          ingredients.single as Map<String, dynamic>;

      expect(
        ingredient['recipeIngredientId'],
        'recipe-line-001',
      );
      expect(ingredient['ingredientId'], 'ingredient-001');
      expect(ingredient['ingredientCode'], 'ING-001');
      expect(ingredient['unitCode'], 'GRAM');
      expect(ingredient['quantity'], 100);
      expect(ingredient['unitCost'], 0.05);
      expect(ingredient['extendedCost'], 5);
    });

    test('generates deterministic Ingredient JSON order', () {
      final PlannedInventoryMovement second = ingredientMovement(
        ingredientId: 'ingredient-002',
        ingredientCode: 'ing-002',
        recipeIngredientId: 'recipe-line-002',
        unitCode: 'ml',
        quantityDelta: -50,
        unitCost: 0.02,
      );

      final PlannedInventoryMovement first = ingredientMovement();

      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: request(),
        plans: <SaleConsumptionPlan>[
          recipePlan(
            movements: <PlannedInventoryMovement>[
              second,
              first,
            ],
            expectedCost: 6,
          ),
        ],
      );

      final String jsonText = snapshot.items.single.ingredientCostJson!;

      final Map<String, dynamic> decoded =
          jsonDecode(jsonText) as Map<String, dynamic>;

      final List<dynamic> ingredients = decoded['ingredients'] as List<dynamic>;

      final Map<String, dynamic> firstJson =
          ingredients[0] as Map<String, dynamic>;

      final Map<String, dynamic> secondJson =
          ingredients[1] as Map<String, dynamic>;

      expect(
        firstJson['recipeIngredientId'],
        'recipe-line-001',
      );

      expect(
        secondJson['recipeIngredientId'],
        'recipe-line-002',
      );

      expect(firstJson['ingredientCode'], 'ING-001');
      expect(secondJson['ingredientCode'], 'ING-002');
      expect(secondJson['unitCode'], 'ML');
    });
  });

  group('NONE Sale Posting costing', () {
    test('creates zero-cost snapshot without Recipe data', () {
      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: request(),
        plans: <SaleConsumptionPlan>[
          nonePlan(),
        ],
      );

      final SalePostingItemCostSnapshot cost = snapshot.items.single;

      expect(cost.inventoryMode, ProductInventoryMode.none);
      expect(cost.unitCost, 0);
      expect(cost.cogs, 0);
      expect(cost.grossProfit, 180);
      expect(cost.grossMargin, 100);
      expect(cost.recipeId, isNull);
      expect(cost.recipeVersion, isNull);
      expect(cost.ingredientCostJson, isNull);

      expect(snapshot.totalCost, 0);
      expect(snapshot.totalCogs, 0);
      expect(snapshot.grossProfit, 180);
      expect(snapshot.grossMargin, 100);
    });

    test('uses zero margin for zero net amount', () {
      final SalePostingRequest freeRequest = request(
        items: <SalePostingItem>[
          item(
            quantity: 1,
            sellingPrice: 0,
            discount: 0,
          ),
        ],
        payments: <SalePostingPayment>[
          payment(amount: 0.001),
        ],
      );

      expect(
        freeRequest.paymentsBalanced,
        isTrue,
      );

      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: freeRequest,
        plans: <SaleConsumptionPlan>[
          nonePlan(
            quantity: 1,
          ),
        ],
      );

      expect(snapshot.items.single.netAmount, 0);
      expect(snapshot.items.single.grossMargin, 0);
      expect(snapshot.grossMargin, 0);
    });
  });

  group('Costing ownership and completeness', () {
    test('finds snapshot by normalized Sale Item ID', () {
      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: request(),
        plans: <SaleConsumptionPlan>[
          directPlan(),
        ],
      );

      expect(
        snapshot.itemCostFor(' sale-item-001 ').cogs,
        50,
      );

      expect(
        () => snapshot.itemCostFor('missing-item'),
        throwsStateError,
      );
    });

    test('protects immutable snapshots', () {
      final SalePostingCostingSnapshot snapshot = planner.createSnapshot(
        request: request(),
        plans: <SaleConsumptionPlan>[
          directPlan(),
        ],
      );

      expect(
        () => snapshot.items.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects plan from another Sale', () {
      expect(
        () => planner.createSnapshot(
          request: request(),
          plans: <SaleConsumptionPlan>[
            directPlan(
              saleId: 'sale-002',
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects mismatched Sale Item', () {
      expect(
        () => planner.createSnapshot(
          request: request(),
          plans: <SaleConsumptionPlan>[
            directPlan(
              productId: 'product-002',
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects missing plan', () {
      expect(
        () => planner.createSnapshot(
          request: request(),
          plans: const <SaleConsumptionPlan>[],
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate item plans', () {
      final SalePostingRequest multiItemRequest = request(
        items: <SalePostingItem>[
          item(),
          item(
            id: 'sale-item-002',
            productId: 'product-002',
            productSku: 'SKU-002',
            productName: 'Second Product',
            quantity: 1,
            sellingPrice: 50,
            discount: 0,
          ),
        ],
        payments: <SalePostingPayment>[
          payment(amount: 230),
        ],
      );

      expect(
        () => planner.createSnapshot(
          request: multiItemRequest,
          plans: <SaleConsumptionPlan>[
            directPlan(),
            directPlan(),
          ],
        ),
        throwsFormatException,
      );
    });
  });

  group('Costing snapshot validation', () {
    test('rejects invalid numeric values', () {
      final SalePostingItemCostSnapshot invalid = SalePostingItemCostSnapshot(
        saleItemId: 'sale-item-001',
        productId: 'product-001',
        inventoryMode: ProductInventoryMode.direct,
        quantity: 2,
        netAmount: 180,
        unitCost: double.nan,
        cogs: 50,
      );

      expect(
        invalid.validate,
        throwsFormatException,
      );
    });

    test('rejects negative COGS', () {
      final SalePostingItemCostSnapshot invalid = SalePostingItemCostSnapshot(
        saleItemId: 'sale-item-001',
        productId: 'product-001',
        inventoryMode: ProductInventoryMode.direct,
        quantity: 2,
        netAmount: 180,
        unitCost: 25,
        cogs: -1,
      );

      expect(
        invalid.validate,
        throwsFormatException,
      );
    });

    test('rejects Recipe snapshot without Recipe data', () {
      final SalePostingItemCostSnapshot invalid = SalePostingItemCostSnapshot(
        saleItemId: 'sale-item-001',
        productId: 'product-001',
        inventoryMode: ProductInventoryMode.recipe,
        quantity: 2,
        netAmount: 180,
        unitCost: 2.5,
        cogs: 5,
      );

      expect(
        invalid.validate,
        throwsFormatException,
      );
    });

    test('rejects NONE snapshot with cost', () {
      final SalePostingItemCostSnapshot invalid = SalePostingItemCostSnapshot(
        saleItemId: 'sale-item-001',
        productId: 'product-001',
        inventoryMode: ProductInventoryMode.none,
        quantity: 2,
        netAmount: 180,
        unitCost: 1,
        cogs: 2,
      );

      expect(
        invalid.validate,
        throwsFormatException,
      );
    });
  });
}
