import 'dart:convert';

import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/models/sale_posting.dart';

class SalePostingItemCostSnapshot {
  final String saleItemId;
  final String productId;
  final ProductInventoryMode inventoryMode;

  final double quantity;
  final double netAmount;
  final double unitCost;
  final double cogs;

  final String? recipeId;
  final int? recipeVersion;
  final String? ingredientCostJson;

  const SalePostingItemCostSnapshot({
    required this.saleItemId,
    required this.productId,
    required this.inventoryMode,
    required this.quantity,
    required this.netAmount,
    required this.unitCost,
    required this.cogs,
    this.recipeId,
    this.recipeVersion,
    this.ingredientCostJson,
  });

  double get grossProfit {
    return netAmount - cogs;
  }

  double get grossMargin {
    if (netAmount <= 0) {
      return 0;
    }

    return grossProfit / netAmount * 100;
  }

  bool get usesDirectInventory {
    return inventoryMode == ProductInventoryMode.direct;
  }

  bool get usesRecipeInventory {
    return inventoryMode == ProductInventoryMode.recipe;
  }

  bool get ignoresInventory {
    return inventoryMode == ProductInventoryMode.none;
  }

  void validate() {
    _requiredText(
      saleItemId,
      'Sale Item ID',
    );

    _requiredText(
      productId,
      'Product ID',
    );

    _positiveNumber(
      quantity,
      'Sale Item quantity',
    );

    _nonNegativeNumber(
      netAmount,
      'Sale Item net amount',
    );

    _nonNegativeNumber(
      unitCost,
      'Sale Item unit cost',
    );

    _nonNegativeNumber(
      cogs,
      'Sale Item COGS',
    );

    _finiteNumber(
      grossProfit,
      'Sale Item gross profit',
    );

    _finiteNumber(
      grossMargin,
      'Sale Item gross margin',
    );

    final String normalizedRecipeId = recipeId?.trim() ?? '';
    final String normalizedIngredientJson = ingredientCostJson?.trim() ?? '';

    switch (inventoryMode) {
      case ProductInventoryMode.direct:
        if (normalizedRecipeId.isNotEmpty ||
            recipeVersion != null ||
            normalizedIngredientJson.isNotEmpty) {
          throw const FormatException(
            'DIRECT Item costing cannot contain Recipe costing data.',
          );
        }

      case ProductInventoryMode.recipe:
        if (normalizedRecipeId.isEmpty) {
          throw const FormatException(
            'RECIPE Item costing requires a Recipe ID.',
          );
        }

        if (normalizedIngredientJson.isEmpty) {
          throw const FormatException(
            'RECIPE Item costing requires Ingredient cost JSON.',
          );
        }

        if (recipeVersion != null && recipeVersion! <= 0) {
          throw const FormatException(
            'Recipe Version must be greater than zero.',
          );
        }

      case ProductInventoryMode.none:
        if (unitCost != 0 || cogs != 0) {
          throw const FormatException(
            'NONE Item costing must have zero cost.',
          );
        }

        if (normalizedRecipeId.isNotEmpty ||
            recipeVersion != null ||
            normalizedIngredientJson.isNotEmpty) {
          throw const FormatException(
            'NONE Item costing cannot contain Recipe costing data.',
          );
        }
    }
  }
}

class SalePostingCostingSnapshot {
  final String saleId;
  final SalePostingRequest request;
  final List<SalePostingItemCostSnapshot> items;

  SalePostingCostingSnapshot({
    required this.saleId,
    required this.request,
    required List<SalePostingItemCostSnapshot> items,
  }) : items = List<SalePostingItemCostSnapshot>.unmodifiable(
          items,
        );

  double get totalCost {
    return items.fold(
      0,
      (
        double total,
        SalePostingItemCostSnapshot item,
      ) {
        return total + item.cogs;
      },
    );
  }

  double get totalCogs {
    return totalCost;
  }

  double get grossProfit {
    return request.grandTotal - totalCogs;
  }

  double get grossMargin {
    if (request.grandTotal <= 0) {
      return 0;
    }

    return grossProfit / request.grandTotal * 100;
  }

  SalePostingItemCostSnapshot itemCostFor(
    String saleItemId,
  ) {
    final String normalizedId = saleItemId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Sale Item ID is required.',
      );
    }

    for (final SalePostingItemCostSnapshot item in items) {
      if (item.saleItemId.trim() == normalizedId) {
        return item;
      }
    }

    throw StateError(
      'Cost snapshot was not found for Sale Item.',
    );
  }

  void validate() {
    _requiredText(
      saleId,
      'Sale ID',
    );

    request.validate();

    if (saleId.trim() != request.saleId.trim()) {
      throw const FormatException(
        'Cost snapshot does not belong to the Sale.',
      );
    }

    if (items.isEmpty) {
      throw const FormatException(
        'Sale costing requires at least one Item snapshot.',
      );
    }

    if (items.length != request.items.length) {
      throw const FormatException(
        'Every Sale Item must have exactly one cost snapshot.',
      );
    }

    final Set<String> itemIds = <String>{};

    for (final SalePostingItemCostSnapshot item in items) {
      item.validate();

      final String normalizedItemId = item.saleItemId.trim();

      if (!itemIds.add(normalizedItemId)) {
        throw const FormatException(
          'Duplicate Sale Item cost snapshot.',
        );
      }

      final bool belongsToRequest = request.items.any(
        (SalePostingItem requestItem) {
          return requestItem.id.trim() == normalizedItemId &&
              requestItem.productId.trim() == item.productId.trim();
        },
      );

      if (!belongsToRequest) {
        throw const FormatException(
          'Cost snapshot does not match a Sale Item.',
        );
      }
    }

    _nonNegativeNumber(
      totalCost,
      'Sale total cost',
    );

    _nonNegativeNumber(
      totalCogs,
      'Sale total COGS',
    );

    _finiteNumber(
      grossProfit,
      'Sale gross profit',
    );

    _finiteNumber(
      grossMargin,
      'Sale gross margin',
    );
  }
}

class SalePostingCostingPlanner {
  const SalePostingCostingPlanner();

  SalePostingCostingSnapshot createSnapshot({
    required SalePostingRequest request,
    required List<SaleConsumptionPlan> plans,
  }) {
    request.validate();

    if (plans.length != request.items.length) {
      throw const FormatException(
        'Every Sale Item must have exactly one costing plan.',
      );
    }

    final Map<String, SaleConsumptionPlan> planByItemId =
        <String, SaleConsumptionPlan>{};

    for (final SaleConsumptionPlan plan in plans) {
      plan.validate();

      if (plan.request.saleId.trim() != request.saleId.trim()) {
        throw const FormatException(
          'Costing plan does not belong to the Sale.',
        );
      }

      final String saleItemId = plan.request.saleItemId.trim();

      if (planByItemId.containsKey(saleItemId)) {
        throw const FormatException(
          'Duplicate Sale Item costing plan.',
        );
      }

      planByItemId[saleItemId] = plan;
    }

    final List<SalePostingItemCostSnapshot> itemSnapshots =
        <SalePostingItemCostSnapshot>[];

    for (final SalePostingItem item in request.items) {
      item.validate();

      final SaleConsumptionPlan? plan = planByItemId[item.id.trim()];

      if (plan == null) {
        throw const FormatException(
          'Every Sale Item must have exactly one costing plan.',
        );
      }

      if (plan.request.saleItemId.trim() != item.id.trim() ||
          plan.request.productId.trim() != item.productId.trim() ||
          plan.request.productSku.trim().toUpperCase() !=
              item.productSku.trim().toUpperCase()) {
        throw const FormatException(
          'Costing plan does not match the Sale Item.',
        );
      }

      itemSnapshots.add(
        _createItemSnapshot(
          item: item,
          plan: plan,
        ),
      );
    }

    final SalePostingCostingSnapshot snapshot = SalePostingCostingSnapshot(
      saleId: request.saleId.trim(),
      request: request,
      items: itemSnapshots,
    );

    snapshot.validate();
    return snapshot;
  }

  SalePostingItemCostSnapshot _createItemSnapshot({
    required SalePostingItem item,
    required SaleConsumptionPlan plan,
  }) {
    final double cogs = plan.expectedCost;

    _nonNegativeNumber(
      cogs,
      'Sale Item COGS',
    );

    final double unitCost = cogs / item.quantity;

    _nonNegativeNumber(
      unitCost,
      'Sale Item unit cost',
    );

    switch (plan.inventoryMode) {
      case ProductInventoryMode.direct:
        return SalePostingItemCostSnapshot(
          saleItemId: item.id.trim(),
          productId: item.productId.trim(),
          inventoryMode: ProductInventoryMode.direct,
          quantity: item.quantity,
          netAmount: item.netAmount,
          unitCost: unitCost,
          cogs: cogs,
          recipeId: null,
          recipeVersion: null,
          ingredientCostJson: null,
        );

      case ProductInventoryMode.recipe:
        final String recipeId = _recipeIdFor(
          plan,
        );

        return SalePostingItemCostSnapshot(
          saleItemId: item.id.trim(),
          productId: item.productId.trim(),
          inventoryMode: ProductInventoryMode.recipe,
          quantity: item.quantity,
          netAmount: item.netAmount,
          unitCost: unitCost,
          cogs: cogs,
          recipeId: recipeId,
          recipeVersion: null,
          ingredientCostJson: _ingredientCostJson(
            plan,
            recipeId: recipeId,
          ),
        );

      case ProductInventoryMode.none:
        return SalePostingItemCostSnapshot(
          saleItemId: item.id.trim(),
          productId: item.productId.trim(),
          inventoryMode: ProductInventoryMode.none,
          quantity: item.quantity,
          netAmount: item.netAmount,
          unitCost: 0,
          cogs: 0,
          recipeId: null,
          recipeVersion: null,
          ingredientCostJson: null,
        );
    }
  }

  String _recipeIdFor(
    SaleConsumptionPlan plan,
  ) {
    if (plan.movements.isEmpty) {
      throw const FormatException(
        'RECIPE costing requires Ingredient movements.',
      );
    }

    final String recipeId = plan.movements.first.recipeId?.trim() ?? '';

    if (recipeId.isEmpty) {
      throw const FormatException(
        'RECIPE costing requires a Recipe ID.',
      );
    }

    for (final PlannedInventoryMovement movement in plan.movements) {
      if (!movement.isIngredientMovement ||
          movement.recipeId?.trim() != recipeId) {
        throw const FormatException(
          'RECIPE costing movements must belong to one Recipe.',
        );
      }
    }

    return recipeId;
  }

  String _ingredientCostJson(
    SaleConsumptionPlan plan, {
    required String recipeId,
  }) {
    final List<PlannedInventoryMovement> sortedMovements =
        List<PlannedInventoryMovement>.from(
      plan.movements,
    );

    sortedMovements.sort(
      (
        PlannedInventoryMovement first,
        PlannedInventoryMovement second,
      ) {
        final String firstLine = first.recipeIngredientId?.trim() ?? '';

        final String secondLine = second.recipeIngredientId?.trim() ?? '';

        final int lineComparison = firstLine.compareTo(
          secondLine,
        );

        if (lineComparison != 0) {
          return lineComparison;
        }

        return first.itemId.trim().compareTo(
              second.itemId.trim(),
            );
      },
    );

    final List<Map<String, Object?>> ingredients = sortedMovements.map(
      (PlannedInventoryMovement movement) {
        movement.validate();

        if (!movement.isIngredientMovement) {
          throw const FormatException(
            'RECIPE costing requires Ingredient movements.',
          );
        }

        final String recipeIngredientId =
            movement.recipeIngredientId?.trim() ?? '';

        if (recipeIngredientId.isEmpty) {
          throw const FormatException(
            'Ingredient costing requires a Recipe Ingredient ID.',
          );
        }

        return <String, Object?>{
          'recipeIngredientId': recipeIngredientId,
          'ingredientId': movement.itemId.trim(),
          'ingredientCode': movement.itemCode.trim().toUpperCase(),
          'unitCode': movement.unitCode.trim().toUpperCase(),
          'quantity': movement.quantityDelta.abs(),
          'unitCost': movement.unitCostSnapshot,
          'extendedCost': movement.totalCostSnapshot,
        };
      },
    ).toList(growable: false);

    return jsonEncode(
      <String, Object?>{
        'recipeId': recipeId.trim(),
        'ingredients': ingredients,
        'totalIngredientCost': plan.expectedCost,
      },
    );
  }
}

void _requiredText(
  String value,
  String fieldName,
) {
  if (value.trim().isEmpty) {
    throw FormatException(
      '$fieldName is required.',
    );
  }
}

void _positiveNumber(
  double value,
  String fieldName,
) {
  _finiteNumber(
    value,
    fieldName,
  );

  if (value <= 0) {
    throw FormatException(
      '$fieldName must be greater than zero.',
    );
  }
}

void _nonNegativeNumber(
  double value,
  String fieldName,
) {
  _finiteNumber(
    value,
    fieldName,
  );

  if (value < 0) {
    throw FormatException(
      '$fieldName cannot be negative.',
    );
  }
}

void _finiteNumber(
  double value,
  String fieldName,
) {
  if (!value.isFinite) {
    throw FormatException(
      '$fieldName must be a valid number.',
    );
  }
}
