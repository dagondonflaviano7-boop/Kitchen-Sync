import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/models/sale_restoration.dart';

class HistoricalSaleSnapshot {
  final String saleId;
  final String transactionNumber;
  final String storeId;
  final String status;

  final double subtotal;
  final double discount;
  final double netSales;
  final double cost;
  final double cogs;
  final double grossProfit;
  final double grossMargin;

  final List<HistoricalSaleItemSnapshot> items;

  HistoricalSaleSnapshot({
    required this.saleId,
    required this.transactionNumber,
    required this.storeId,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.netSales,
    required this.cost,
    required this.cogs,
    required this.grossProfit,
    required this.grossMargin,
    required List<HistoricalSaleItemSnapshot> items,
  }) : items = List<HistoricalSaleItemSnapshot>.unmodifiable(
          items,
        );

  void validate() {
    _requiredText(
      saleId,
      'Historical Sale ID',
    );

    _requiredText(
      transactionNumber,
      'Historical Sale transaction number',
    );

    _requiredText(
      storeId,
      'Historical Sale Store ID',
    );

    _requiredText(
      status,
      'Historical Sale status',
    );

    _nonNegativeNumber(
      subtotal,
      'Historical Sale subtotal',
    );

    _nonNegativeNumber(
      discount,
      'Historical Sale discount',
    );

    _nonNegativeNumber(
      netSales,
      'Historical Sale net sales',
    );

    _nonNegativeNumber(
      cost,
      'Historical Sale cost',
    );

    _nonNegativeNumber(
      cogs,
      'Historical Sale COGS',
    );

    _finiteNumber(
      grossProfit,
      'Historical Sale gross profit',
    );

    _finiteNumber(
      grossMargin,
      'Historical Sale gross margin',
    );

    if (items.isEmpty) {
      throw const FormatException(
        'Historical Sale requires at least one Item.',
      );
    }

    final Set<String> itemIds = <String>{};

    for (final HistoricalSaleItemSnapshot item in items) {
      item.validate();

      if (item.saleId.trim() != saleId.trim()) {
        throw const FormatException(
          'Historical Sale Item does not belong to the Sale.',
        );
      }

      if (!itemIds.add(item.saleItemId.trim())) {
        throw const FormatException(
          'Duplicate historical Sale Item.',
        );
      }
    }
  }
}

class HistoricalSaleItemSnapshot {
  final String saleItemId;
  final String saleId;

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

  const HistoricalSaleItemSnapshot({
    required this.saleItemId,
    required this.saleId,
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

  bool get requiresInventoryMovement {
    return !(cogs == 0 && unitCost == 0);
  }

  void validate() {
    _requiredText(
      saleItemId,
      'Historical Sale Item ID',
    );

    _requiredText(
      saleId,
      'Historical Sale ID',
    );

    _requiredText(
      productId,
      'Historical Product ID',
    );

    _requiredText(
      productSku,
      'Historical Product SKU',
    );

    _requiredText(
      productName,
      'Historical Product name',
    );

    _positiveNumber(
      quantity,
      'Historical Sale Item quantity',
    );

    _nonNegativeNumber(
      sellingPrice,
      'Historical Sale Item selling price',
    );

    _nonNegativeNumber(
      discount,
      'Historical Sale Item discount',
    );

    _nonNegativeNumber(
      netAmount,
      'Historical Sale Item net amount',
    );

    _nonNegativeNumber(
      unitCost,
      'Historical Sale Item unit cost',
    );

    _nonNegativeNumber(
      cogs,
      'Historical Sale Item COGS',
    );

    if (recipeVersion != null && recipeVersion! <= 0) {
      throw const FormatException(
        'Historical Recipe Version must be greater than zero.',
      );
    }
  }
}

class HistoricalSaleMovementSnapshot {
  final String movementId;

  final ConsumptionItemType itemType;
  final String itemId;
  final String itemCode;
  final String unitCode;

  final double quantityDelta;
  final double unitCostSnapshot;

  final String sourceSaleId;
  final String sourceSaleItemId;
  final String storeId;

  final String? recipeId;
  final String? recipeIngredientId;
  final String? reversalOfMovementId;

  const HistoricalSaleMovementSnapshot({
    required this.movementId,
    required this.itemType,
    required this.itemId,
    required this.itemCode,
    required this.unitCode,
    required this.quantityDelta,
    required this.unitCostSnapshot,
    required this.sourceSaleId,
    required this.sourceSaleItemId,
    required this.storeId,
    this.recipeId,
    this.recipeIngredientId,
    this.reversalOfMovementId,
  });

  double get historicalCost {
    return quantityDelta.abs() * unitCostSnapshot;
  }

  void validate() {
    _requiredText(
      movementId,
      'Historical movement ID',
    );

    _requiredText(
      itemId,
      'Historical movement Item ID',
    );

    _requiredText(
      itemCode,
      'Historical movement Item Code',
    );

    _requiredText(
      unitCode,
      'Historical movement unit',
    );

    _requiredText(
      sourceSaleId,
      'Historical movement source Sale ID',
    );

    _requiredText(
      sourceSaleItemId,
      'Historical movement source Sale Item ID',
    );

    _requiredText(
      storeId,
      'Historical movement Store ID',
    );

    _finiteNumber(
      quantityDelta,
      'Historical movement quantity',
    );

    if (quantityDelta >= 0) {
      throw const FormatException(
        'Original movement must have a negative quantity.',
      );
    }

    _nonNegativeNumber(
      unitCostSnapshot,
      'Historical movement unit cost',
    );

    final String restoredBy = reversalOfMovementId?.trim() ?? '';

    if (restoredBy.isNotEmpty) {
      throw const FormatException(
        'Original movement was already restored.',
      );
    }

    final String normalizedRecipeId = recipeId?.trim() ?? '';

    final String normalizedRecipeIngredientId =
        recipeIngredientId?.trim() ?? '';

    if (itemType == ConsumptionItemType.ingredient) {
      if (normalizedRecipeId.isEmpty || normalizedRecipeIngredientId.isEmpty) {
        throw const FormatException(
          'Historical Ingredient movement requires Recipe lineage.',
        );
      }
    }

    if (itemType == ConsumptionItemType.product &&
        (normalizedRecipeId.isNotEmpty ||
            normalizedRecipeIngredientId.isNotEmpty)) {
      throw const FormatException(
        'Historical Product movement cannot contain Recipe lineage.',
      );
    }
  }
}

class SaleRestorationPlanner {
  static const double tolerance = 0.000001;

  const SaleRestorationPlanner();

  SaleRestorationPlan createPlan({
    required SaleRestorationRequest request,
    required HistoricalSaleSnapshot sale,
    required List<HistoricalSaleMovementSnapshot> movements,
  }) {
    request.validate();
    sale.validate();

    if (sale.status.trim().toUpperCase() != 'COMPLETED') {
      throw const FormatException(
        'Only a completed Sale can be restored.',
      );
    }

    if (request.originalSaleId.trim() != sale.saleId.trim()) {
      throw const FormatException(
        'Restoration request does not match the original Sale.',
      );
    }

    final Map<String, HistoricalSaleItemSnapshot> itemsById =
        <String, HistoricalSaleItemSnapshot>{
      for (final HistoricalSaleItemSnapshot item in sale.items)
        item.saleItemId.trim(): item,
    };

    final Set<String> movementIds = <String>{};
    final Map<String, List<HistoricalSaleMovementSnapshot>> movementsByItem =
        <String, List<HistoricalSaleMovementSnapshot>>{};

    for (final HistoricalSaleMovementSnapshot movement in movements) {
      movement.validate();

      if (!movementIds.add(movement.movementId.trim())) {
        throw const FormatException(
          'Duplicate historical movement.',
        );
      }

      if (movement.sourceSaleId.trim() != sale.saleId.trim()) {
        throw const FormatException(
          'Historical movement does not belong to the original Sale.',
        );
      }

      if (movement.storeId.trim() != sale.storeId.trim()) {
        throw const FormatException(
          'Historical movement does not belong to the Sale Store.',
        );
      }

      final String sourceItemId = movement.sourceSaleItemId.trim();

      if (!itemsById.containsKey(sourceItemId)) {
        throw const FormatException(
          'Historical movement does not match a Sale Item.',
        );
      }

      movementsByItem
          .putIfAbsent(
            sourceItemId,
            () => <HistoricalSaleMovementSnapshot>[],
          )
          .add(movement);
    }

    for (final HistoricalSaleItemSnapshot item in sale.items) {
      final List<HistoricalSaleMovementSnapshot> itemMovements =
          movementsByItem[item.saleItemId.trim()] ??
              const <HistoricalSaleMovementSnapshot>[];

      if (item.requiresInventoryMovement && itemMovements.isEmpty) {
        throw const FormatException(
          'Historical inventory movement was not found for Sale Item.',
        );
      }

      final double movementCost = itemMovements.fold<double>(
        0,
        (
          double total,
          HistoricalSaleMovementSnapshot movement,
        ) {
          return total +
              movement.quantityDelta.abs() * movement.unitCostSnapshot;
        },
      );

      if ((movementCost - item.cogs).abs() > tolerance) {
        throw const FormatException(
          'Historical movement cost does not match Sale Item COGS.',
        );
      }
    }

    final List<SaleRestorationItemPlan> restorationItems = sale.items.map(
      (HistoricalSaleItemSnapshot item) {
        return SaleRestorationItemPlan(
          restorationItemId: _restorationItemId(
            request,
            item,
          ),
          originalSaleItemId: item.saleItemId,
          productId: item.productId,
          productSku: item.productSku,
          productName: item.productName,
          quantity: item.quantity,
          sellingPrice: item.sellingPrice,
          discount: item.discount,
          netAmount: item.netAmount,
          unitCost: item.unitCost,
          cogs: item.cogs,
          recipeVersion: item.recipeVersion,
          ingredientCostJson: item.ingredientCostJson,
        );
      },
    ).toList(growable: false);

    final List<SaleRestorationMovementPlan> restorationMovements =
        movements.map(
      (HistoricalSaleMovementSnapshot movement) {
        return SaleRestorationMovementPlan(
          restorationMovementId: _restorationMovementId(
            request,
            movement,
          ),
          restorationId: request.restorationId,
          originalMovementId: movement.movementId,
          reversalOfMovementId: movement.movementId,
          itemType: movement.itemType,
          itemId: movement.itemId,
          itemCode: movement.itemCode,
          unitCode: movement.unitCode,
          quantityDelta: -movement.quantityDelta,
          unitCostSnapshot: movement.unitCostSnapshot,
          originalSaleId: movement.sourceSaleId,
          originalSaleItemId: movement.sourceSaleItemId,
          storeId: movement.storeId,
          recipeId: movement.recipeId,
          recipeIngredientId: movement.recipeIngredientId,
        );
      },
    ).toList(growable: false);

    final SaleRestorationPlan plan = SaleRestorationPlan(
      request: request,
      originalTransactionNumber: sale.transactionNumber,
      storeId: sale.storeId,
      items: restorationItems,
      movements: restorationMovements,
      subtotalReversal: -sale.subtotal,
      discountReversal: -sale.discount,
      netSalesReversal: -sale.netSales,
      costReversal: -sale.cost,
      cogsReversal: -sale.cogs,
      grossProfitReversal: -sale.grossProfit,
      grossMarginSnapshot: sale.grossMargin,
    );

    plan.validate();
    return plan;
  }

  String _restorationItemId(
    SaleRestorationRequest request,
    HistoricalSaleItemSnapshot item,
  ) {
    return '${request.restorationId.trim()}:'
        'ITEM:${item.saleItemId.trim()}';
  }

  String _restorationMovementId(
    SaleRestorationRequest request,
    HistoricalSaleMovementSnapshot movement,
  ) {
    return '${request.restorationId.trim()}:'
        'MOVEMENT:${movement.movementId.trim()}';
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
  _finiteNumber(value, fieldName);

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
  _finiteNumber(value, fieldName);

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
