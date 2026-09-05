import 'package:kitchen_sync/domain/models/product.dart';

enum ConsumptionItemType {
  product,
  ingredient,
}

enum ConsumptionOperation {
  consume,
  restore,
}

String consumptionItemTypeToStorage(
  ConsumptionItemType type,
) {
  return switch (type) {
    ConsumptionItemType.product => 'PRODUCT',
    ConsumptionItemType.ingredient => 'INGREDIENT',
  };
}

ConsumptionItemType consumptionItemTypeFromStorage(
  Object? value,
) {
  return switch (value?.toString().trim().toUpperCase()) {
    'PRODUCT' => ConsumptionItemType.product,
    'INGREDIENT' => ConsumptionItemType.ingredient,
    _ => throw FormatException(
        'Unsupported consumption item type: '
        '$value',
      ),
  };
}

String consumptionOperationToStorage(
  ConsumptionOperation operation,
) {
  return switch (operation) {
    ConsumptionOperation.consume => 'CONSUME',
    ConsumptionOperation.restore => 'RESTORE',
  };
}

ConsumptionOperation consumptionOperationFromStorage(
  Object? value,
) {
  return switch (value?.toString().trim().toUpperCase()) {
    'CONSUME' => ConsumptionOperation.consume,
    'RESTORE' => ConsumptionOperation.restore,
    _ => throw FormatException(
        'Unsupported consumption operation: '
        '$value',
      ),
  };
}

class SaleConsumptionRequest {
  final String saleId;
  final String saleItemId;
  final String storeId;

  final String productId;
  final String productSku;
  final double quantitySold;

  final DateTime occurredAt;
  final String performedBy;
  final String deviceId;

  const SaleConsumptionRequest({
    required this.saleId,
    required this.saleItemId,
    required this.storeId,
    required this.productId,
    required this.productSku,
    required this.quantitySold,
    required this.occurredAt,
    required this.performedBy,
    required this.deviceId,
  });

  String get idempotencyKey {
    return [
      'SALE',
      saleId.trim(),
      saleItemId.trim(),
      'CONSUME',
    ].join(':');
  }

  void validate() {
    _requiredText(
      saleId,
      'Sale ID',
    );

    _requiredText(
      saleItemId,
      'Sale Item ID',
    );

    _requiredText(
      storeId,
      'Store ID',
    );

    _requiredText(
      productId,
      'Product ID',
    );

    _requiredText(
      productSku,
      'Product SKU',
    );

    _positiveNumber(
      quantitySold,
      'Quantity Sold',
    );

    _requiredText(
      performedBy,
      'Performed By',
    );

    _requiredText(
      deviceId,
      'Device ID',
    );
  }
}

class PlannedInventoryMovement {
  final String idempotencyKey;

  final ConsumptionOperation operation;
  final ConsumptionItemType itemType;

  final String itemId;
  final String itemCode;
  final String unitCode;

  final double quantityDelta;
  final double unitCostSnapshot;

  final String sourceSaleId;
  final String sourceSaleItemId;

  final String storeId;
  final String performedBy;
  final String deviceId;
  final DateTime occurredAt;

  final String? recipeId;
  final String? recipeIngredientId;
  final String? reversalOfMovementId;

  const PlannedInventoryMovement({
    required this.idempotencyKey,
    required this.operation,
    required this.itemType,
    required this.itemId,
    required this.itemCode,
    required this.unitCode,
    required this.quantityDelta,
    required this.unitCostSnapshot,
    required this.sourceSaleId,
    required this.sourceSaleItemId,
    required this.storeId,
    required this.performedBy,
    required this.deviceId,
    required this.occurredAt,
    this.recipeId,
    this.recipeIngredientId,
    this.reversalOfMovementId,
  });

  bool get isProductMovement {
    return itemType == ConsumptionItemType.product;
  }

  bool get isIngredientMovement {
    return itemType == ConsumptionItemType.ingredient;
  }

  bool get isConsumption {
    return operation == ConsumptionOperation.consume;
  }

  bool get isRestoration {
    return operation == ConsumptionOperation.restore;
  }

  double get absoluteQuantity {
    return quantityDelta.abs();
  }

  double get totalCostSnapshot {
    return absoluteQuantity * unitCostSnapshot;
  }

  void validate() {
    _requiredText(
      idempotencyKey,
      'Idempotency Key',
    );

    _requiredText(
      itemId,
      'Item ID',
    );

    _requiredText(
      itemCode,
      'Item Code',
    );

    _requiredText(
      unitCode,
      'Unit Code',
    );

    _requiredText(
      sourceSaleId,
      'Source Sale ID',
    );

    _requiredText(
      sourceSaleItemId,
      'Source Sale Item ID',
    );

    _requiredText(
      storeId,
      'Store ID',
    );

    _requiredText(
      performedBy,
      'Performed By',
    );

    _requiredText(
      deviceId,
      'Device ID',
    );

    if (!quantityDelta.isFinite || quantityDelta == 0) {
      throw const FormatException(
        'Quantity Delta must be a finite '
        'non-zero number.',
      );
    }

    if (operation == ConsumptionOperation.consume && quantityDelta >= 0) {
      throw const FormatException(
        'Consumption quantity must be negative.',
      );
    }

    if (operation == ConsumptionOperation.restore && quantityDelta <= 0) {
      throw const FormatException(
        'Restoration quantity must be positive.',
      );
    }

    _nonNegativeNumber(
      unitCostSnapshot,
      'Unit Cost Snapshot',
    );

    if (itemType == ConsumptionItemType.product) {
      if (_optionalText(recipeId) != null ||
          _optionalText(
                recipeIngredientId,
              ) !=
              null) {
        throw const FormatException(
          'Product movements cannot contain '
          'Recipe references.',
        );
      }
    }

    if (itemType == ConsumptionItemType.ingredient) {
      _requiredText(
        recipeId,
        'Recipe ID',
      );

      _requiredText(
        recipeIngredientId,
        'Recipe Ingredient ID',
      );
    }

    if (operation == ConsumptionOperation.restore &&
        _optionalText(
              reversalOfMovementId,
            ) ==
            null) {
      throw const FormatException(
        'Restoration requires the original '
        'Movement ID.',
      );
    }
  }
}

class SaleConsumptionPlan {
  final SaleConsumptionRequest request;
  final ProductInventoryMode inventoryMode;

  final List<PlannedInventoryMovement> movements;

  final double expectedCost;

  const SaleConsumptionPlan({
    required this.request,
    required this.inventoryMode,
    required this.movements,
    required this.expectedCost,
  });

  bool get affectsInventory {
    return movements.isNotEmpty;
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

  int get movementCount {
    return movements.length;
  }

  void validate() {
    request.validate();

    _nonNegativeNumber(
      expectedCost,
      'Expected Cost',
    );

    final Set<String> idempotencyKeys = <String>{};

    for (final PlannedInventoryMovement movement in movements) {
      movement.validate();

      if (movement.sourceSaleId.trim() != request.saleId.trim()) {
        throw const FormatException(
          'Movement Sale ID must match '
          'the consumption request.',
        );
      }

      if (movement.sourceSaleItemId.trim() != request.saleItemId.trim()) {
        throw const FormatException(
          'Movement Sale Item ID must match '
          'the consumption request.',
        );
      }

      if (movement.storeId.trim() != request.storeId.trim()) {
        throw const FormatException(
          'Movement Store ID must match '
          'the consumption request.',
        );
      }

      if (!idempotencyKeys.add(
        movement.idempotencyKey.trim(),
      )) {
        throw const FormatException(
          'Duplicate movement idempotency key.',
        );
      }
    }

    switch (inventoryMode) {
      case ProductInventoryMode.direct:
        if (movements.length != 1 || !movements.first.isProductMovement) {
          throw const FormatException(
            'DIRECT Products require exactly '
            'one Product movement.',
          );
        }

      case ProductInventoryMode.recipe:
        if (movements.isEmpty ||
            movements.any(
              (
                PlannedInventoryMovement movement,
              ) {
                return !movement.isIngredientMovement;
              },
            )) {
          throw const FormatException(
            'RECIPE Products require one or '
            'more Ingredient movements.',
          );
        }

      case ProductInventoryMode.none:
        if (movements.isNotEmpty) {
          throw const FormatException(
            'NONE Products cannot create '
            'inventory movements.',
          );
        }

        if (expectedCost != 0) {
          throw const FormatException(
            'NONE Products must have zero '
            'inventory consumption cost.',
          );
        }
    }

    final double movementCost = movements.fold(
      0,
      (
        double total,
        PlannedInventoryMovement movement,
      ) {
        return total + movement.totalCostSnapshot;
      },
    );

    if ((movementCost - expectedCost).abs() > 0.000001) {
      throw const FormatException(
        'Expected Cost must equal the total '
        'planned movement cost.',
      );
    }
  }
}

String _requiredText(
  Object? value,
  String fieldName,
) {
  final String normalized = value?.toString().trim() ?? '';

  if (normalized.isEmpty) {
    throw FormatException(
      '$fieldName is required.',
    );
  }

  return normalized;
}

String? _optionalText(
  Object? value,
) {
  final String normalized = value?.toString().trim() ?? '';

  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}

double _positiveNumber(
  Object? value,
  String fieldName,
) {
  final double number = _number(
    value,
    fieldName,
  );

  if (number <= 0) {
    throw FormatException(
      '$fieldName must be greater than zero.',
    );
  }

  return number;
}

double _nonNegativeNumber(
  Object? value,
  String fieldName,
) {
  final double number = _number(
    value,
    fieldName,
  );

  if (number < 0) {
    throw FormatException(
      '$fieldName cannot be negative.',
    );
  }

  return number;
}

double _number(
  Object? value,
  String fieldName,
) {
  final double? number = value is num
      ? value.toDouble()
      : double.tryParse(
          value?.toString() ?? '',
        );

  if (number == null || !number.isFinite) {
    throw FormatException(
      '$fieldName must be a valid number.',
    );
  }

  return number;
}
