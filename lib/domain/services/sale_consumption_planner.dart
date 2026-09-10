import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';

class SaleConsumptionPlanner {
  const SaleConsumptionPlanner();

  SaleConsumptionPlan createPlan({
    required SaleConsumptionRequest request,
    required Product product,
    Recipe? recipe,
  }) {
    request.validate();
    product.validate();

    _validateProductRequest(
      request,
      product,
    );

    if (!product.active || product.isDeleted) {
      throw StateError(
        'Sale consumption requires an active Product.',
      );
    }

    final SaleConsumptionPlan plan = switch (product.inventoryMode) {
      ProductInventoryMode.direct => _createDirectPlan(
          request,
          product,
        ),
      ProductInventoryMode.recipe => _createRecipePlan(
          request,
          product,
          recipe,
        ),
      ProductInventoryMode.none => _createNoInventoryPlan(
          request,
        ),
    };

    plan.validate();
    return plan;
  }

  SaleConsumptionPlan _createDirectPlan(
    SaleConsumptionRequest request,
    Product product,
  ) {
    final double quantity = request.quantitySold;

    final PlannedInventoryMovement movement = PlannedInventoryMovement(
      idempotencyKey: _movementKey(
        request: request,
        itemType: ConsumptionItemType.product,
        itemId: product.id,
      ),
      operation: ConsumptionOperation.consume,
      itemType: ConsumptionItemType.product,
      itemId: product.id.trim(),
      itemCode: product.sku.trim().toUpperCase(),
      unitCode: 'EACH',
      quantityDelta: -quantity,
      unitCostSnapshot: product.cost,
      sourceSaleId: request.saleId.trim(),
      sourceSaleItemId: request.saleItemId.trim(),
      storeId: request.storeId.trim(),
      performedBy: request.performedBy.trim(),
      deviceId: request.deviceId.trim(),
      occurredAt: request.occurredAt.toUtc(),
    );

    return SaleConsumptionPlan(
      request: request,
      inventoryMode: ProductInventoryMode.direct,
      movements: <PlannedInventoryMovement>[
        movement,
      ],
      expectedCost: quantity * product.cost,
    );
  }

  SaleConsumptionPlan _createRecipePlan(
    SaleConsumptionRequest request,
    Product product,
    Recipe? recipe,
  ) {
    final String expectedRecipeId = product.recipeId?.trim() ?? '';

    if (expectedRecipeId.isEmpty) {
      throw StateError(
        'RECIPE Product does not have '
        'a linked Recipe.',
      );
    }

    if (recipe == null) {
      throw StateError(
        'The linked Recipe is required '
        'for Sale consumption.',
      );
    }

    if (recipe.id.trim() != expectedRecipeId) {
      throw StateError(
        'Loaded Recipe does not match '
        'the Product Recipe.',
      );
    }

    recipe.validate();

    if (!recipe.active || recipe.isDeleted) {
      throw StateError(
        'Sale consumption requires '
        'an active Recipe.',
      );
    }

    if (recipe.ingredients.isEmpty) {
      throw StateError(
        'The linked Recipe has no Ingredients.',
      );
    }

    final double productionFactor = request.quantitySold / recipe.yieldQuantity;

    if (!productionFactor.isFinite || productionFactor <= 0) {
      throw StateError(
        'Recipe production factor '
        'must be greater than zero.',
      );
    }

    final List<PlannedInventoryMovement> movements = recipe.ingredients.map(
      (RecipeIngredient ingredient) {
        ingredient.validate();

        final double quantity = ingredient.quantityRequired * productionFactor;

        if (!quantity.isFinite || quantity <= 0) {
          throw StateError(
            'Planned Ingredient quantity '
            'must be greater than zero.',
          );
        }

        return PlannedInventoryMovement(
          idempotencyKey: _movementKey(
            request: request,
            itemType: ConsumptionItemType.ingredient,
            itemId: ingredient.ingredientId,
            recipeIngredientId: ingredient.id,
          ),
          operation: ConsumptionOperation.consume,
          itemType: ConsumptionItemType.ingredient,
          itemId: ingredient.ingredientId.trim(),
          itemCode: ingredient.ingredientSku.trim().toUpperCase(),
          unitCode: ingredient.usageUnitCode.trim().toUpperCase(),
          quantityDelta: -quantity,
          unitCostSnapshot: ingredient.costPerUsageUnit,
          sourceSaleId: request.saleId.trim(),
          sourceSaleItemId: request.saleItemId.trim(),
          storeId: request.storeId.trim(),
          performedBy: request.performedBy.trim(),
          deviceId: request.deviceId.trim(),
          occurredAt: request.occurredAt.toUtc(),
          recipeId: recipe.id.trim(),
          recipeIngredientId: ingredient.id.trim(),
        );
      },
    ).toList(growable: false);

    final double expectedCost = movements.fold(
      0,
      (
        double total,
        PlannedInventoryMovement movement,
      ) {
        return total + movement.totalCostSnapshot;
      },
    );

    return SaleConsumptionPlan(
      request: request,
      inventoryMode: ProductInventoryMode.recipe,
      movements: List<PlannedInventoryMovement>.unmodifiable(
        movements,
      ),
      expectedCost: expectedCost,
    );
  }

  SaleConsumptionPlan _createNoInventoryPlan(
    SaleConsumptionRequest request,
  ) {
    return SaleConsumptionPlan(
      request: request,
      inventoryMode: ProductInventoryMode.none,
      movements: const <PlannedInventoryMovement>[],
      expectedCost: 0,
    );
  }

  void _validateProductRequest(
    SaleConsumptionRequest request,
    Product product,
  ) {
    if (request.productId.trim() != product.id.trim()) {
      throw StateError(
        'Sale Product ID does not match '
        'the loaded Product.',
      );
    }

    if (request.productSku.trim().toUpperCase() !=
        product.sku.trim().toUpperCase()) {
      throw StateError(
        'Sale Product SKU does not match '
        'the loaded Product.',
      );
    }
  }

  String _movementKey({
    required SaleConsumptionRequest request,
    required ConsumptionItemType itemType,
    required String itemId,
    String? recipeIngredientId,
  }) {
    final List<String> parts = <String>[
      'SALE',
      request.saleId.trim(),
      request.saleItemId.trim(),
      consumptionItemTypeToStorage(itemType),
      itemId.trim(),
    ];

    final String recipeLine = recipeIngredientId?.trim() ?? '';

    if (recipeLine.isNotEmpty) {
      parts.add(recipeLine);
    }

    parts.add('CONSUME');

    return parts.join(':');
  }
}
