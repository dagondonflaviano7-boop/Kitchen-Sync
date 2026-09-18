import 'package:kitchen_sync/domain/models/product.dart';

enum InventoryStockStatus {
  inStock,
  lowStock,
  outOfStock,
}

class InventoryProductView {
  static const double lowStockThreshold = 5;

  final Product product;
  final String storeId;
  final double quantity;
  final double averageCost;
  final DateTime? inventoryUpdatedAt;

  const InventoryProductView({
    required this.product,
    required this.storeId,
    required this.quantity,
    required this.averageCost,
    required this.inventoryUpdatedAt,
  });

  InventoryStockStatus get stockStatus {
    if (quantity <= 0) {
      return InventoryStockStatus.outOfStock;
    }

    if (quantity <= lowStockThreshold) {
      return InventoryStockStatus.lowStock;
    }

    return InventoryStockStatus.inStock;
  }

  bool get hasInventoryBalance {
    return inventoryUpdatedAt != null;
  }

  double get inventoryValue {
    return quantity * averageCost;
  }

  void validate() {
    product.validate();

    if (storeId.trim().isEmpty) {
      throw const FormatException(
        'Inventory Product Store ID is required.',
      );
    }

    if (!quantity.isFinite) {
      throw const FormatException(
        'Inventory Product quantity must be valid.',
      );
    }

    if (!averageCost.isFinite || averageCost < 0) {
      throw const FormatException(
        'Inventory Product average cost must be '
        'a non-negative number.',
      );
    }
  }

  factory InventoryProductView.fromSqlite(
    Map<String, Object?> map,
  ) {
    final Product product = Product.fromSqlite(map);

    final InventoryProductView view = InventoryProductView(
      product: product,
      storeId: _requiredString(
        map['inventory_store_id'],
        'Inventory Store ID',
      ),
      quantity: _requiredNumber(
        map['inventory_quantity'] ?? 0,
        'Inventory quantity',
      ),
      averageCost: _requiredNumber(
        map['inventory_average_cost'] ?? 0,
        'Inventory average cost',
      ),
      inventoryUpdatedAt: _optionalDateTime(
        map['inventory_updated_at'],
      ),
    );

    view.validate();
    return view;
  }
}

String _requiredString(
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

double _requiredNumber(
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

DateTime? _optionalDateTime(
  Object? value,
) {
  final String normalized = value?.toString().trim() ?? '';

  if (normalized.isEmpty) {
    return null;
  }

  final DateTime? parsed = DateTime.tryParse(normalized);

  if (parsed == null) {
    throw const FormatException(
      'Inventory Updated At must be a valid date.',
    );
  }

  return parsed;
}
