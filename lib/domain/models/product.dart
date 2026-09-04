enum ProductInventoryMode {
  direct,
  recipe,
  none,
}

enum ProductCostingMethod {
  manual,
  ingredient,
  hybrid,
}

String productInventoryModeToStorage(
  ProductInventoryMode mode,
) {
  switch (mode) {
    case ProductInventoryMode.direct:
      return 'DIRECT';
    case ProductInventoryMode.recipe:
      return 'RECIPE';
    case ProductInventoryMode.none:
      return 'NONE';
  }
}

ProductInventoryMode productInventoryModeFromStorage(
  Object? value,
) {
  switch (value?.toString().trim().toUpperCase()) {
    case 'DIRECT':
      return ProductInventoryMode.direct;
    case 'RECIPE':
      return ProductInventoryMode.recipe;
    case 'NONE':
      return ProductInventoryMode.none;
    default:
      throw FormatException(
        'Unsupported Product inventory mode: $value',
      );
  }
}

String productCostingMethodToStorage(
  ProductCostingMethod method,
) {
  switch (method) {
    case ProductCostingMethod.manual:
      return 'MANUAL';
    case ProductCostingMethod.ingredient:
      return 'INGREDIENT';
    case ProductCostingMethod.hybrid:
      return 'HYBRID';
  }
}

ProductCostingMethod productCostingMethodFromStorage(
  Object? value,
) {
  switch (value?.toString().trim().toUpperCase()) {
    case 'MANUAL':
      return ProductCostingMethod.manual;
    case 'INGREDIENT':
      return ProductCostingMethod.ingredient;
    case 'HYBRID':
      return ProductCostingMethod.hybrid;
    default:
      throw FormatException(
        'Unsupported Product costing method: $value',
      );
  }
}

class Product {
  final String id;
  final String sku;
  final String? barcode;
  final String productName;

  final String? department;
  final String? departmentName;
  final String? classCode;
  final String? className;
  final String? subclass;
  final String? subclassName;

  final String? supplierId;
  final String? supplierName;
  final String? brandName;
  final String? productUsage;
  final String? description;

  final double cost;
  final double retailPrice;
  final double vat;
  final bool active;

  final ProductInventoryMode inventoryMode;
  final ProductCostingMethod costingMethod;
  final String? recipeId;

  final String? imageUrl;
  final String? imagePublicId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.sku,
    this.barcode,
    required this.productName,
    this.department,
    this.departmentName,
    this.classCode,
    this.className,
    this.subclass,
    this.subclassName,
    this.supplierId,
    this.supplierName,
    this.brandName,
    this.productUsage,
    this.description,
    this.cost = 0,
    this.retailPrice = 0,
    this.vat = 0,
    this.active = true,
    required this.inventoryMode,
    this.costingMethod = ProductCostingMethod.manual,
    this.recipeId,
    this.imageUrl,
    this.imagePublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get usesDirectInventory {
    return inventoryMode == ProductInventoryMode.direct;
  }

  bool get usesRecipeInventory {
    return inventoryMode == ProductInventoryMode.recipe;
  }

  bool get ignoresInventory {
    return inventoryMode == ProductInventoryMode.none;
  }

  bool get usesIngredientCosting {
    return costingMethod == ProductCostingMethod.ingredient ||
        costingMethod == ProductCostingMethod.hybrid;
  }

  bool get hasRecipe {
    return _optionalString(recipeId) != null;
  }

  double get priceIncludingVat {
    return retailPrice + vat;
  }

  double get grossProfit {
    return retailPrice - cost;
  }

  double get grossMargin {
    if (retailPrice <= 0) {
      return 0;
    }

    return grossProfit / retailPrice * 100;
  }

  void validate() {
    _requiredString(
      id,
      'Product ID',
    );

    _requiredString(
      sku,
      'SKU',
    );

    _requiredString(
      productName,
      'Product Name',
    );

    _nonNegativeNumber(
      cost,
      'Cost',
    );

    _nonNegativeNumber(
      retailPrice,
      'Retail Price',
    );

    _nonNegativeNumber(
      vat,
      'VAT',
    );

    if (createdAt.isAfter(updatedAt)) {
      throw const FormatException(
        'Created At cannot be after Updated At.',
      );
    }

    final String? normalizedRecipeId = _optionalString(recipeId);

    switch (inventoryMode) {
      case ProductInventoryMode.recipe:
        if (normalizedRecipeId == null) {
          throw const FormatException(
            'Recipe ID is required when '
            'Inventory Mode is RECIPE.',
          );
        }

      case ProductInventoryMode.direct:
        if (normalizedRecipeId != null) {
          throw const FormatException(
            'Recipe ID must be empty when '
            'Inventory Mode is DIRECT.',
          );
        }

        if (costingMethod == ProductCostingMethod.ingredient) {
          throw const FormatException(
            'INGREDIENT costing requires '
            'RECIPE Inventory Mode.',
          );
        }

      case ProductInventoryMode.none:
        if (normalizedRecipeId != null) {
          throw const FormatException(
            'Recipe ID must be empty when '
            'Inventory Mode is NONE.',
          );
        }

        if (costingMethod == ProductCostingMethod.ingredient) {
          throw const FormatException(
            'INGREDIENT costing requires '
            'RECIPE Inventory Mode.',
          );
        }
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'sku': sku.trim().toUpperCase(),
      'barcode': _optionalString(barcode),
      'product_name': productName.trim(),
      'department': _optionalString(department),
      'department_name': _optionalString(departmentName),
      'class_code': _optionalUppercaseString(classCode),
      'class_name': _optionalString(className),
      'subclass': _optionalUppercaseString(subclass),
      'subclass_name': _optionalString(subclassName),
      'supplier_id': _optionalString(supplierId),
      'supplier_name': _optionalString(supplierName),
      'brand_name': _optionalString(brandName),
      'product_usage': _optionalString(productUsage),
      'description': _optionalString(description),
      'cost': cost,
      'retail_price': retailPrice,
      'vat': vat,
      'active': active ? 1 : 0,
      'inventory_mode': productInventoryModeToStorage(
        inventoryMode,
      ),
      'costing_method': productCostingMethodToStorage(
        costingMethod,
      ),
      'recipe_id': _optionalString(recipeId),
      'image_url': _optionalString(imageUrl),
      'image_public_id': _optionalString(imagePublicId),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Product.fromSqlite(
    Map<String, Object?> map,
  ) {
    final Product product = Product(
      id: _requiredString(
        map['id'],
        'Product ID',
      ),
      sku: _requiredString(
        map['sku'],
        'SKU',
      ).toUpperCase(),
      barcode: _optionalString(
        map['barcode'],
      ),
      productName: _requiredString(
        map['product_name'],
        'Product Name',
      ),
      department: _optionalString(
        map['department'],
      ),
      departmentName: _optionalString(
        map['department_name'],
      ),
      classCode: _optionalUppercaseString(
        map['class_code'],
      ),
      className: _optionalString(
        map['class_name'],
      ),
      subclass: _optionalUppercaseString(
        map['subclass'],
      ),
      subclassName: _optionalString(
        map['subclass_name'],
      ),
      supplierId: _optionalString(
        map['supplier_id'],
      ),
      supplierName: _optionalString(
        map['supplier_name'],
      ),
      brandName: _optionalString(
        map['brand_name'],
      ),
      productUsage: _optionalString(
        map['product_usage'],
      ),
      description: _optionalString(
        map['description'],
      ),
      cost: _nonNegativeNumber(
        map['cost'] ?? 0,
        'Cost',
      ),
      retailPrice: _nonNegativeNumber(
        map['retail_price'] ?? 0,
        'Retail Price',
      ),
      vat: _nonNegativeNumber(
        map['vat'] ?? 0,
        'VAT',
      ),
      active: _sqliteBool(
        map['active'],
        'Active',
      ),
      inventoryMode: productInventoryModeFromStorage(
        map['inventory_mode'],
      ),
      costingMethod: productCostingMethodFromStorage(
        map['costing_method'] ?? 'MANUAL',
      ),
      recipeId: _optionalString(
        map['recipe_id'],
      ),
      imageUrl: _optionalString(
        map['image_url'],
      ),
      imagePublicId: _optionalString(
        map['image_public_id'],
      ),
      createdAt: _requiredDateTime(
        map['created_at'],
        'Created At',
      ),
      updatedAt: _requiredDateTime(
        map['updated_at'],
        'Updated At',
      ),
    );

    product.validate();
    return product;
  }

  Map<String, Object?> toFirebase() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'sku': sku.trim().toUpperCase(),
      'barcode': _optionalString(barcode),
      'productName': productName.trim(),
      'department': _optionalString(department),
      'departmentName': _optionalString(departmentName),
      'classCode': _optionalUppercaseString(classCode),
      'className': _optionalString(className),
      'subclass': _optionalUppercaseString(subclass),
      'subclassName': _optionalString(subclassName),
      'supplierId': _optionalString(supplierId),
      'supplierName': _optionalString(supplierName),
      'brandName': _optionalString(brandName),
      'productUsage': _optionalString(productUsage),
      'description': _optionalString(description),
      'cost': cost,
      'retailPrice': retailPrice,
      'vat': vat,
      'active': active,
      'inventoryMode': productInventoryModeToStorage(
        inventoryMode,
      ),
      'costingMethod': productCostingMethodToStorage(
        costingMethod,
      ),
      'recipeId': _optionalString(recipeId),
      'imageUrl': _optionalString(imageUrl),
      'imagePublicId': _optionalString(imagePublicId),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Product.fromFirebase(
    String firebaseId,
    Map<Object?, Object?> map,
  ) {
    final String normalizedId = firebaseId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Product Firebase ID is required.',
      );
    }

    final Product product = Product(
      id: normalizedId,
      sku: _requiredString(
        map['sku'],
        'SKU',
      ).toUpperCase(),
      barcode: _optionalString(
        map['barcode'],
      ),
      productName: _requiredString(
        map['productName'],
        'Product Name',
      ),
      department: _optionalString(
        map['department'],
      ),
      departmentName: _optionalString(
        map['departmentName'],
      ),
      classCode: _optionalUppercaseString(
        map['classCode'],
      ),
      className: _optionalString(
        map['className'],
      ),
      subclass: _optionalUppercaseString(
        map['subclass'],
      ),
      subclassName: _optionalString(
        map['subclassName'],
      ),
      supplierId: _optionalString(
        map['supplierId'],
      ),
      supplierName: _optionalString(
        map['supplierName'],
      ),
      brandName: _optionalString(
        map['brandName'],
      ),
      productUsage: _optionalString(
        map['productUsage'],
      ),
      description: _optionalString(
        map['description'],
      ),
      cost: _nonNegativeNumber(
        map['cost'] ?? 0,
        'Cost',
      ),
      retailPrice: _nonNegativeNumber(
        map['retailPrice'] ?? 0,
        'Retail Price',
      ),
      vat: _nonNegativeNumber(
        map['vat'] ?? 0,
        'VAT',
      ),
      active: _firebaseBool(
        map['active'],
        'Active',
      ),
      inventoryMode: productInventoryModeFromStorage(
        map['inventoryMode'],
      ),
      costingMethod: productCostingMethodFromStorage(
        map['costingMethod'] ?? 'MANUAL',
      ),
      recipeId: _optionalString(
        map['recipeId'],
      ),
      imageUrl: _optionalString(
        map['imageUrl'],
      ),
      imagePublicId: _optionalString(
        map['imagePublicId'],
      ),
      createdAt: _requiredDateTime(
        map['createdAt'],
        'Created At',
      ),
      updatedAt: _requiredDateTime(
        map['updatedAt'],
        'Updated At',
      ),
    );

    product.validate();
    return product;
  }

  Product copyWith({
    String? id,
    String? sku,
    Object? barcode = _notProvided,
    String? productName,
    Object? department = _notProvided,
    Object? departmentName = _notProvided,
    Object? classCode = _notProvided,
    Object? className = _notProvided,
    Object? subclass = _notProvided,
    Object? subclassName = _notProvided,
    Object? supplierId = _notProvided,
    Object? supplierName = _notProvided,
    Object? brandName = _notProvided,
    Object? productUsage = _notProvided,
    Object? description = _notProvided,
    double? cost,
    double? retailPrice,
    double? vat,
    bool? active,
    ProductInventoryMode? inventoryMode,
    ProductCostingMethod? costingMethod,
    Object? recipeId = _notProvided,
    Object? imageUrl = _notProvided,
    Object? imagePublicId = _notProvided,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: identical(
        barcode,
        _notProvided,
      )
          ? this.barcode
          : barcode as String?,
      productName: productName ?? this.productName,
      department: identical(
        department,
        _notProvided,
      )
          ? this.department
          : department as String?,
      departmentName: identical(
        departmentName,
        _notProvided,
      )
          ? this.departmentName
          : departmentName as String?,
      classCode: identical(
        classCode,
        _notProvided,
      )
          ? this.classCode
          : classCode as String?,
      className: identical(
        className,
        _notProvided,
      )
          ? this.className
          : className as String?,
      subclass: identical(
        subclass,
        _notProvided,
      )
          ? this.subclass
          : subclass as String?,
      subclassName: identical(
        subclassName,
        _notProvided,
      )
          ? this.subclassName
          : subclassName as String?,
      supplierId: identical(
        supplierId,
        _notProvided,
      )
          ? this.supplierId
          : supplierId as String?,
      supplierName: identical(
        supplierName,
        _notProvided,
      )
          ? this.supplierName
          : supplierName as String?,
      brandName: identical(
        brandName,
        _notProvided,
      )
          ? this.brandName
          : brandName as String?,
      productUsage: identical(
        productUsage,
        _notProvided,
      )
          ? this.productUsage
          : productUsage as String?,
      description: identical(
        description,
        _notProvided,
      )
          ? this.description
          : description as String?,
      cost: cost ?? this.cost,
      retailPrice: retailPrice ?? this.retailPrice,
      vat: vat ?? this.vat,
      active: active ?? this.active,
      inventoryMode: inventoryMode ?? this.inventoryMode,
      costingMethod: costingMethod ?? this.costingMethod,
      recipeId: identical(
        recipeId,
        _notProvided,
      )
          ? this.recipeId
          : recipeId as String?,
      imageUrl: identical(
        imageUrl,
        _notProvided,
      )
          ? this.imageUrl
          : imageUrl as String?,
      imagePublicId: identical(
        imagePublicId,
        _notProvided,
      )
          ? this.imagePublicId
          : imagePublicId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const Object _notProvided = Object();

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

String? _optionalString(
  Object? value,
) {
  final String normalized = value?.toString().trim() ?? '';

  return normalized.isEmpty ? null : normalized;
}

String? _optionalUppercaseString(
  Object? value,
) {
  return _optionalString(value)?.toUpperCase();
}

double _nonNegativeNumber(
  Object? value,
  String fieldName,
) {
  final double? number = value is num
      ? value.toDouble()
      : double.tryParse(
          value?.toString() ?? '',
        );

  if (number == null || !number.isFinite || number < 0) {
    throw FormatException(
      '$fieldName must be zero or greater.',
    );
  }

  return number;
}

bool _sqliteBool(
  Object? value,
  String fieldName,
) {
  if (value == 1 || value?.toString().toLowerCase() == 'true') {
    return true;
  }

  if (value == 0 || value?.toString().toLowerCase() == 'false') {
    return false;
  }

  throw FormatException(
    '$fieldName must be a Boolean.',
  );
}

bool _firebaseBool(
  Object? value,
  String fieldName,
) {
  if (value is bool) {
    return value;
  }

  return _sqliteBool(
    value,
    fieldName,
  );
}

DateTime _requiredDateTime(
  Object? value,
  String fieldName,
) {
  final DateTime? dateTime = DateTime.tryParse(
    value?.toString() ?? '',
  );

  if (dateTime == null) {
    throw FormatException(
      '$fieldName must be a valid date.',
    );
  }

  return dateTime.toUtc();
}
