import 'package:kitchen_sync/domain/models/sale_consumption.dart';

enum SaleRestorationOperation {
  voidSale,
  refund,
}

String saleRestorationOperationToStorage(
  SaleRestorationOperation operation,
) {
  return switch (operation) {
    SaleRestorationOperation.voidSale => 'VOID',
    SaleRestorationOperation.refund => 'REFUND',
  };
}

SaleRestorationOperation saleRestorationOperationFromStorage(
  String value,
) {
  return switch (value.trim().toUpperCase()) {
    'VOID' => SaleRestorationOperation.voidSale,
    'REFUND' => SaleRestorationOperation.refund,
    _ => throw const FormatException(
        'Unsupported Sale Restoration operation.',
      ),
  };
}

class SaleRestorationRequest {
  final String restorationId;
  final String restorationTransactionNumber;
  final String originalSaleId;
  final SaleRestorationOperation operation;
  final String reason;
  final String performedBy;
  final String deviceId;
  final DateTime occurredAt;

  const SaleRestorationRequest({
    required this.restorationId,
    required this.restorationTransactionNumber,
    required this.originalSaleId,
    required this.operation,
    required this.reason,
    required this.performedBy,
    required this.deviceId,
    required this.occurredAt,
  });

  String get idempotencyKey {
    return 'RESTORE:'
        '${saleRestorationOperationToStorage(operation)}:'
        '${originalSaleId.trim()}';
  }

  void validate() {
    _requiredText(
      restorationId,
      'Restoration ID',
    );

    _requiredText(
      restorationTransactionNumber,
      'Restoration Transaction Number',
    );

    _requiredText(
      originalSaleId,
      'Original Sale ID',
    );

    if (reason.trim().isEmpty) {
      throw const FormatException(
        'Restoration reason is required.',
      );
    }

    _requiredText(
      performedBy,
      'Performed By',
    );

    _requiredText(
      deviceId,
      'Device ID',
    );

    if (restorationId.trim() == originalSaleId.trim()) {
      throw const FormatException(
        'Restoration ID must differ from the original Sale ID.',
      );
    }

    if (idempotencyKey.trim().isEmpty) {
      throw const FormatException(
        'Restoration idempotency key is required.',
      );
    }
  }
}

class SaleRestorationItemPlan {
  final String restorationItemId;
  final String originalSaleItemId;
  final String productId;
  final String productSku;
  final String productName;

  final double quantity;
  final double sellingPrice;
  final double discount;
  final double netAmount;

  final double unitCost;
  final double cogs;

  final int? recipeVersion;
  final String? ingredientCostJson;

  const SaleRestorationItemPlan({
    required this.restorationItemId,
    required this.originalSaleItemId,
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.discount,
    required this.netAmount,
    required this.unitCost,
    required this.cogs,
    this.recipeVersion,
    this.ingredientCostJson,
  });

  void validate() {
    _requiredText(
      restorationItemId,
      'Restoration Item ID',
    );

    _requiredText(
      originalSaleItemId,
      'Original Sale Item ID',
    );

    _requiredText(
      productId,
      'Product ID',
    );

    _requiredText(
      productSku,
      'Product SKU',
    );

    _requiredText(
      productName,
      'Product Name',
    );

    _positiveNumber(
      quantity,
      'Restoration Item quantity',
    );

    _nonNegativeNumber(
      sellingPrice,
      'Restoration Item selling price',
    );

    _nonNegativeNumber(
      discount,
      'Restoration Item discount',
    );

    _nonNegativeNumber(
      netAmount,
      'Restoration Item net amount',
    );

    _nonNegativeNumber(
      unitCost,
      'Restoration Item unit cost',
    );

    _nonNegativeNumber(
      cogs,
      'Restoration Item COGS',
    );

    if (discount > quantity * sellingPrice) {
      throw const FormatException(
        'Restoration Item discount cannot exceed gross amount.',
      );
    }

    if (recipeVersion != null && recipeVersion! <= 0) {
      throw const FormatException(
        'Recipe Version must be greater than zero.',
      );
    }
  }
}

class SaleRestorationMovementPlan {
  final String restorationMovementId;
  final String restorationId;

  final String originalMovementId;
  final String reversalOfMovementId;

  final ConsumptionItemType itemType;
  final String itemId;
  final String itemCode;
  final String unitCode;

  final double quantityDelta;
  final double unitCostSnapshot;

  final String originalSaleId;
  final String originalSaleItemId;
  final String storeId;

  final String? recipeId;
  final String? recipeIngredientId;

  const SaleRestorationMovementPlan({
    required this.restorationMovementId,
    required this.restorationId,
    required this.originalMovementId,
    required this.reversalOfMovementId,
    required this.itemType,
    required this.itemId,
    required this.itemCode,
    required this.unitCode,
    required this.quantityDelta,
    required this.unitCostSnapshot,
    required this.originalSaleId,
    required this.originalSaleItemId,
    required this.storeId,
    this.recipeId,
    this.recipeIngredientId,
  });

  String get idempotencyKey {
    return 'RESTORE:$restorationId:'
        '${originalMovementId.trim()}';
  }

  double get totalCostSnapshot {
    return quantityDelta * unitCostSnapshot;
  }

  bool get restoresProduct {
    return itemType == ConsumptionItemType.product;
  }

  bool get restoresIngredient {
    return itemType == ConsumptionItemType.ingredient;
  }

  void validate() {
    _requiredText(
      restorationMovementId,
      'Restoration Movement ID',
    );

    _requiredText(
      restorationId,
      'Restoration ID',
    );

    _requiredText(
      originalMovementId,
      'Original Movement ID',
    );

    _requiredText(
      reversalOfMovementId,
      'Reversal Of Movement ID',
    );

    if (reversalOfMovementId.trim() != originalMovementId.trim()) {
      throw const FormatException(
        'Restoration movement must reference its '
        'original movement.',
      );
    }

    _requiredText(
      itemId,
      'Restoration movement Item ID',
    );

    _requiredText(
      itemCode,
      'Restoration movement Item Code',
    );

    _requiredText(
      unitCode,
      'Restoration movement Unit Code',
    );

    _requiredText(
      originalSaleId,
      'Original Sale ID',
    );

    _requiredText(
      originalSaleItemId,
      'Original Sale Item ID',
    );

    _requiredText(
      storeId,
      'Store ID',
    );

    _finiteNumber(
      quantityDelta,
      'Restoration movement quantity',
    );

    if (quantityDelta <= 0) {
      throw const FormatException(
        'Restoration movement quantity must be '
        'greater than zero.',
      );
    }

    _nonNegativeNumber(
      unitCostSnapshot,
      'Restoration movement unit cost',
    );

    _finiteNumber(
      totalCostSnapshot,
      'Restoration movement total cost',
    );

    final String normalizedRecipeId = recipeId?.trim() ?? '';

    final String normalizedRecipeIngredientId =
        recipeIngredientId?.trim() ?? '';

    if (itemType == ConsumptionItemType.ingredient) {
      if (normalizedRecipeId.isEmpty) {
        throw const FormatException(
          'Ingredient restoration requires a Recipe ID.',
        );
      }

      if (normalizedRecipeIngredientId.isEmpty) {
        throw const FormatException(
          'Ingredient restoration requires a '
          'Recipe Ingredient ID.',
        );
      }
    }

    if (itemType == ConsumptionItemType.product &&
        (normalizedRecipeId.isNotEmpty ||
            normalizedRecipeIngredientId.isNotEmpty)) {
      throw const FormatException(
        'Product restoration cannot contain Recipe lineage.',
      );
    }

    if (idempotencyKey.trim().isEmpty) {
      throw const FormatException(
        'Restoration movement idempotency key is required.',
      );
    }
  }
}

class SaleRestorationPlan {
  final SaleRestorationRequest request;
  final String originalTransactionNumber;
  final String storeId;

  final List<SaleRestorationItemPlan> items;
  final List<SaleRestorationMovementPlan> movements;

  final double subtotalReversal;
  final double discountReversal;
  final double netSalesReversal;
  final double costReversal;
  final double cogsReversal;
  final double grossProfitReversal;
  final double grossMarginSnapshot;

  SaleRestorationPlan({
    required this.request,
    required this.originalTransactionNumber,
    required this.storeId,
    required List<SaleRestorationItemPlan> items,
    required List<SaleRestorationMovementPlan> movements,
    required this.subtotalReversal,
    required this.discountReversal,
    required this.netSalesReversal,
    required this.costReversal,
    required this.cogsReversal,
    required this.grossProfitReversal,
    required this.grossMarginSnapshot,
  })  : items = List<SaleRestorationItemPlan>.unmodifiable(
          items,
        ),
        movements = List<SaleRestorationMovementPlan>.unmodifiable(
          movements,
        );

  SaleRestorationItemPlan itemForOriginalSaleItem(
    String originalSaleItemId,
  ) {
    final String normalizedId = originalSaleItemId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Original Sale Item ID is required.',
      );
    }

    for (final SaleRestorationItemPlan item in items) {
      if (item.originalSaleItemId.trim() == normalizedId) {
        return item;
      }
    }

    throw StateError(
      'Restoration Item was not found.',
    );
  }

  SaleRestorationMovementPlan movementForOriginalMovement(
    String originalMovementId,
  ) {
    final String normalizedId = originalMovementId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Original Movement ID is required.',
      );
    }

    for (final SaleRestorationMovementPlan movement in movements) {
      if (movement.originalMovementId.trim() == normalizedId) {
        return movement;
      }
    }

    throw StateError(
      'Restoration movement was not found.',
    );
  }

  void validate() {
    request.validate();

    _requiredText(
      originalTransactionNumber,
      'Original Transaction Number',
    );

    _requiredText(
      storeId,
      'Store ID',
    );

    if (items.isEmpty) {
      throw const FormatException(
        'Sale Restoration requires at least one Item.',
      );
    }

    final Set<String> originalSaleItemIds = <String>{};

    for (final SaleRestorationItemPlan item in items) {
      item.validate();

      final String normalizedItemId = item.originalSaleItemId.trim();

      if (!originalSaleItemIds.add(normalizedItemId)) {
        throw const FormatException(
          'Duplicate original Sale Item restoration.',
        );
      }
    }

    final Set<String> originalMovementIds = <String>{};

    for (final SaleRestorationMovementPlan movement in movements) {
      movement.validate();

      final String normalizedMovementId = movement.originalMovementId.trim();

      if (!originalMovementIds.add(normalizedMovementId)) {
        throw const FormatException(
          'Duplicate original movement restoration.',
        );
      }

      if (movement.restorationId.trim() != request.restorationId.trim()) {
        throw const FormatException(
          'Restoration movement does not belong to '
          'the Restoration request.',
        );
      }

      if (movement.originalSaleId.trim() != request.originalSaleId.trim()) {
        throw const FormatException(
          'Restoration movement does not belong to '
          'the original Sale.',
        );
      }

      if (movement.storeId.trim() != storeId.trim()) {
        throw const FormatException(
          'Restoration movement does not belong to '
          'the Restoration Store.',
        );
      }

      if (!originalSaleItemIds.contains(
        movement.originalSaleItemId.trim(),
      )) {
        throw const FormatException(
          'Restoration movement does not match a '
          'Restoration Item.',
        );
      }
    }

    _zeroOrNegativeNumber(
      subtotalReversal,
      'Restoration subtotal reversal',
    );

    _zeroOrNegativeNumber(
      discountReversal,
      'Restoration discount reversal',
    );

    _zeroOrNegativeNumber(
      netSalesReversal,
      'Restoration net-sales reversal',
    );

    _zeroOrNegativeNumber(
      costReversal,
      'Restoration cost reversal',
    );

    _zeroOrNegativeNumber(
      cogsReversal,
      'Restoration COGS reversal',
    );

    _finiteNumber(
      grossProfitReversal,
      'Restoration gross-profit reversal',
    );

    _finiteNumber(
      grossMarginSnapshot,
      'Restoration gross-margin snapshot',
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

void _zeroOrNegativeNumber(
  double value,
  String fieldName,
) {
  _finiteNumber(
    value,
    fieldName,
  );

  if (value > 0) {
    throw FormatException(
      '$fieldName must be zero or negative.',
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
