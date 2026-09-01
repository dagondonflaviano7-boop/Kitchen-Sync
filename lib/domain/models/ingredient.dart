import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

enum IngredientCategory {
  meat,
  poultry,
  seafood,
  vegetables,
  fruits,
  dairy,
  dryGoods,
  riceAndGrains,
  spicesAndSeasonings,
  saucesAndCondiments,
  beverages,
  packaging,
  cleaningSupplies,
  other,
}

String ingredientCategoryToStorage(
  IngredientCategory category,
) {
  return switch (category) {
    IngredientCategory.meat => 'MEAT',
    IngredientCategory.poultry => 'POULTRY',
    IngredientCategory.seafood => 'SEAFOOD',
    IngredientCategory.vegetables => 'VEGETABLES',
    IngredientCategory.fruits => 'FRUITS',
    IngredientCategory.dairy => 'DAIRY',
    IngredientCategory.dryGoods => 'DRY_GOODS',
    IngredientCategory.riceAndGrains => 'RICE_AND_GRAINS',
    IngredientCategory.spicesAndSeasonings => 'SPICES_AND_SEASONINGS',
    IngredientCategory.saucesAndCondiments => 'SAUCES_AND_CONDIMENTS',
    IngredientCategory.beverages => 'BEVERAGES',
    IngredientCategory.packaging => 'PACKAGING',
    IngredientCategory.cleaningSupplies => 'CLEANING_SUPPLIES',
    IngredientCategory.other => 'OTHER',
  };
}

IngredientCategory ingredientCategoryFromStorage(
  String value,
) {
  return switch (value.trim().toUpperCase()) {
    'MEAT' => IngredientCategory.meat,
    'POULTRY' => IngredientCategory.poultry,
    'SEAFOOD' => IngredientCategory.seafood,
    'VEGETABLES' => IngredientCategory.vegetables,
    'FRUITS' => IngredientCategory.fruits,
    'DAIRY' => IngredientCategory.dairy,
    'DRY_GOODS' => IngredientCategory.dryGoods,
    'RICE_AND_GRAINS' => IngredientCategory.riceAndGrains,
    'SPICES_AND_SEASONINGS' => IngredientCategory.spicesAndSeasonings,
    'SAUCES_AND_CONDIMENTS' => IngredientCategory.saucesAndCondiments,
    'BEVERAGES' => IngredientCategory.beverages,
    'PACKAGING' => IngredientCategory.packaging,
    'CLEANING_SUPPLIES' => IngredientCategory.cleaningSupplies,
    'OTHER' => IngredientCategory.other,
    _ => throw FormatException(
        'Unsupported Ingredient category: $value',
      ),
  };
}

String ingredientCategoryLabel(
  IngredientCategory category,
) {
  return switch (category) {
    IngredientCategory.meat => 'Meat',
    IngredientCategory.poultry => 'Poultry',
    IngredientCategory.seafood => 'Seafood',
    IngredientCategory.vegetables => 'Vegetables',
    IngredientCategory.fruits => 'Fruits',
    IngredientCategory.dairy => 'Dairy',
    IngredientCategory.dryGoods => 'Dry Goods',
    IngredientCategory.riceAndGrains => 'Rice and Grains',
    IngredientCategory.spicesAndSeasonings => 'Spices and Seasonings',
    IngredientCategory.saucesAndCondiments => 'Sauces and Condiments',
    IngredientCategory.beverages => 'Beverages',
    IngredientCategory.packaging => 'Packaging',
    IngredientCategory.cleaningSupplies => 'Cleaning Supplies',
    IngredientCategory.other => 'Other',
  };
}

class Ingredient {
  final String id;
  final String ingredientSku;
  final String ingredientName;
  final IngredientCategory category;

  final String? primarySupplierId;
  final String? supplierNameSnapshot;

  final String usageUnitCode;
  final String? purchaseUnitCode;
  final double conversionFactor;

  final double latestPurchaseCost;
  final double reorderLevel;
  final double? parLevel;

  final bool active;
  final String? notes;
  final String? imagePath;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  final MasterSyncStatus syncStatus;
  final int serverVersion;
  final DateTime? deletedAt;

  const Ingredient({
    required this.id,
    required this.ingredientSku,
    required this.ingredientName,
    required this.category,
    required this.primarySupplierId,
    required this.supplierNameSnapshot,
    required this.usageUnitCode,
    required this.purchaseUnitCode,
    required this.conversionFactor,
    required this.latestPurchaseCost,
    required this.reorderLevel,
    required this.parLevel,
    required this.active,
    required this.notes,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.syncStatus = MasterSyncStatus.pending,
    this.serverVersion = 0,
    this.deletedAt,
  });

  double get costPerUsageUnit {
    if (conversionFactor <= 0) {
      return 0;
    }

    return latestPurchaseCost / conversionFactor;
  }

  bool get isDeleted {
    return deletedAt != null;
  }

  bool get hasSupplier {
    return primarySupplierId != null && primarySupplierId!.trim().isNotEmpty;
  }

  factory Ingredient.fromSqlite(
    Map<String, Object?> map,
  ) {
    final Ingredient ingredient = Ingredient(
      id: _requiredString(
        map['id'],
        'id',
      ),
      ingredientSku: _requiredCode(
        map['ingredient_sku'],
        'ingredient_sku',
      ),
      ingredientName: _requiredString(
        map['ingredient_name'],
        'ingredient_name',
      ),
      category: ingredientCategoryFromStorage(
        _requiredString(
          map['category'] ?? 'OTHER',
          'category',
        ),
      ),
      primarySupplierId: _optionalString(
        map['supplier_id'],
      ),
      supplierNameSnapshot: _optionalString(
        map['supplier_name'],
      ),
      usageUnitCode: _requiredCode(
        map['unit_of_measure'],
        'unit_of_measure',
      ),
      purchaseUnitCode: _optionalCode(
        map['purchase_unit'],
      ),
      conversionFactor: _positiveNumber(
        map['conversion_factor'] ?? 1,
        'conversion_factor',
      ),
      latestPurchaseCost: _nonNegativeNumber(
        map['cost'] ?? 0,
        'cost',
      ),
      reorderLevel: _nonNegativeNumber(
        map['minimum_stock'] ?? 0,
        'minimum_stock',
      ),
      parLevel: _optionalNonNegativeNumber(
        map['maximum_stock'],
        'maximum_stock',
      ),
      active: _sqliteBool(
        map['active'],
        'active',
      ),
      notes: _optionalString(
        map['notes'],
      ),
      imagePath: _optionalString(
        map['image_path'],
      ),
      createdAt: _requiredDateTime(
        map['created_at'],
        'created_at',
      ),
      updatedAt: _requiredDateTime(
        map['updated_at'],
        'updated_at',
      ),
      createdBy: _optionalString(
        map['created_by'],
      ),
      updatedBy: _optionalString(
        map['updated_by'],
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['sync_status']?.toString() ?? 'PENDING',
      ),
      serverVersion: _nonNegativeInteger(
        map['server_version'] ?? 0,
        'server_version',
      ),
      deletedAt: _optionalDateTime(
        map['deleted_at'],
      ),
    );

    ingredient.validate();
    return ingredient;
  }

  factory Ingredient.fromFirebase(
    String key,
    Map<Object?, Object?> data,
  ) {
    final Map<String, dynamic> map = data.map(
      (Object? key, Object? value) {
        return MapEntry(
          key.toString(),
          value,
        );
      },
    );

    final Ingredient ingredient = Ingredient(
      id: _requiredString(
        map['id'] ?? key,
        'id',
      ),
      ingredientSku: _requiredCode(
        map['ingredientSku'],
        'ingredientSku',
      ),
      ingredientName: _requiredString(
        map['ingredientName'],
        'ingredientName',
      ),
      category: ingredientCategoryFromStorage(
        map['category']?.toString() ?? 'OTHER',
      ),
      primarySupplierId: _optionalString(
        map['supplierId'],
      ),
      supplierNameSnapshot: _optionalString(
        map['supplierName'],
      ),
      usageUnitCode: _requiredCode(
        map['unitOfMeasure'],
        'unitOfMeasure',
      ),
      purchaseUnitCode: _optionalCode(
        map['purchaseUnit'],
      ),
      conversionFactor: _positiveNumber(
        map['conversionFactor'] ?? 1,
        'conversionFactor',
      ),
      latestPurchaseCost: _nonNegativeNumber(
        map['cost'] ?? 0,
        'cost',
      ),
      reorderLevel: _nonNegativeNumber(
        map['minimumStock'] ?? 0,
        'minimumStock',
      ),
      parLevel: _optionalNonNegativeNumber(
        map['maximumStock'],
        'maximumStock',
      ),
      active: _requiredBool(
        map['active'],
        'active',
      ),
      notes: _optionalString(
        map['notes'],
      ),
      imagePath: _optionalString(
        map['imagePath'],
      ),
      createdAt: _requiredDateTime(
        map['createdAt'],
        'createdAt',
      ),
      updatedAt: _requiredDateTime(
        map['updatedAt'],
        'updatedAt',
      ),
      createdBy: _optionalString(
        map['createdBy'],
      ),
      updatedBy: _optionalString(
        map['updatedBy'],
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['syncStatus']?.toString() ?? 'SYNCED',
      ),
      serverVersion: _nonNegativeInteger(
        map['serverVersion'] ?? 0,
        'serverVersion',
      ),
      deletedAt: _optionalDateTime(
        map['deletedAt'],
      ),
    );

    ingredient.validate();
    return ingredient;
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException(
        'Ingredient ID is required.',
      );
    }

    if (ingredientSku.trim().isEmpty) {
      throw const FormatException(
        'Ingredient SKU is required.',
      );
    }

    if (ingredientName.trim().isEmpty) {
      throw const FormatException(
        'Ingredient name is required.',
      );
    }

    if (usageUnitCode.trim().isEmpty) {
      throw const FormatException(
        'Usage Unit is required.',
      );
    }

    if (conversionFactor <= 0) {
      throw const FormatException(
        'Conversion factor must be greater than zero.',
      );
    }

    if (latestPurchaseCost < 0) {
      throw const FormatException(
        'Latest purchase cost must be zero or greater.',
      );
    }

    if (reorderLevel < 0) {
      throw const FormatException(
        'Reorder level must be zero or greater.',
      );
    }

    if (parLevel != null && parLevel! < 0) {
      throw const FormatException(
        'Par level must be zero or greater.',
      );
    }

    if (parLevel != null && parLevel! < reorderLevel) {
      throw const FormatException(
        'Par level cannot be lower than the reorder level.',
      );
    }

    final bool hasSupplierId = primarySupplierId?.trim().isNotEmpty == true;

    final bool hasSupplierName =
        supplierNameSnapshot?.trim().isNotEmpty == true;

    if (hasSupplierId != hasSupplierName) {
      throw const FormatException(
        'Supplier ID and Supplier name must be provided together.',
      );
    }

    if (serverVersion < 0) {
      throw const FormatException(
        'Server version must be zero or greater.',
      );
    }

    if (deletedAt != null && active) {
      throw const FormatException(
        'A deleted Ingredient cannot remain active.',
      );
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'ingredient_sku': ingredientSku.trim().toUpperCase(),
      'ingredient_name': ingredientName.trim(),
      'category': ingredientCategoryToStorage(category),
      'supplier_id': _normalizedOptionalString(
        primarySupplierId,
      ),
      'supplier_name': _normalizedOptionalString(
        supplierNameSnapshot,
      ),
      'unit_of_measure': usageUnitCode.trim().toUpperCase(),
      'purchase_unit': _normalizedOptionalCode(
        purchaseUnitCode,
      ),
      'conversion_factor': conversionFactor,
      'cost': latestPurchaseCost,
      'minimum_stock': reorderLevel,
      'maximum_stock': parLevel,
      'active': active ? 1 : 0,
      'notes': _normalizedOptionalString(notes),
      'image_path': _normalizedOptionalString(imagePath),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'created_by': _normalizedOptionalString(createdBy),
      'updated_by': _normalizedOptionalString(updatedBy),
      'sync_status': masterSyncStatusToStorage(
        syncStatus,
      ),
      'server_version': serverVersion,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toFirebase() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'ingredientSku': ingredientSku.trim().toUpperCase(),
      'ingredientName': ingredientName.trim(),
      'category': ingredientCategoryToStorage(category),
      'supplierId': _normalizedOptionalString(
        primarySupplierId,
      ),
      'supplierName': _normalizedOptionalString(
        supplierNameSnapshot,
      ),
      'unitOfMeasure': usageUnitCode.trim().toUpperCase(),
      'purchaseUnit': _normalizedOptionalCode(
        purchaseUnitCode,
      ),
      'conversionFactor': conversionFactor,
      'cost': latestPurchaseCost,
      'minimumStock': reorderLevel,
      'maximumStock': parLevel,
      'active': active,
      'notes': _normalizedOptionalString(notes),
      'imagePath': _normalizedOptionalString(imagePath),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'createdBy': _normalizedOptionalString(createdBy),
      'updatedBy': _normalizedOptionalString(updatedBy),
      'syncStatus': masterSyncStatusToStorage(
        syncStatus,
      ),
      'serverVersion': serverVersion,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  Ingredient copyWith({
    String? id,
    String? ingredientSku,
    String? ingredientName,
    IngredientCategory? category,
    String? primarySupplierId,
    bool clearPrimarySupplier = false,
    String? supplierNameSnapshot,
    String? usageUnitCode,
    String? purchaseUnitCode,
    bool clearPurchaseUnit = false,
    double? conversionFactor,
    double? latestPurchaseCost,
    double? reorderLevel,
    double? parLevel,
    bool clearParLevel = false,
    bool? active,
    String? notes,
    bool clearNotes = false,
    String? imagePath,
    bool clearImagePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool clearCreatedBy = false,
    String? updatedBy,
    bool clearUpdatedBy = false,
    MasterSyncStatus? syncStatus,
    int? serverVersion,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Ingredient(
      id: id ?? this.id,
      ingredientSku: ingredientSku ?? this.ingredientSku,
      ingredientName: ingredientName ?? this.ingredientName,
      category: category ?? this.category,
      primarySupplierId: clearPrimarySupplier
          ? null
          : primarySupplierId ?? this.primarySupplierId,
      supplierNameSnapshot: clearPrimarySupplier
          ? null
          : supplierNameSnapshot ?? this.supplierNameSnapshot,
      usageUnitCode: usageUnitCode ?? this.usageUnitCode,
      purchaseUnitCode:
          clearPurchaseUnit ? null : purchaseUnitCode ?? this.purchaseUnitCode,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      latestPurchaseCost: latestPurchaseCost ?? this.latestPurchaseCost,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      parLevel: clearParLevel ? null : parLevel ?? this.parLevel,
      active: active ?? this.active,
      notes: clearNotes ? null : notes ?? this.notes,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  static String _requiredString(
    Object? value,
    String field,
  ) {
    final String result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      throw FormatException(
        '$field is required.',
      );
    }

    return result;
  }

  static String _requiredCode(
    Object? value,
    String field,
  ) {
    return _requiredString(
      value,
      field,
    ).toUpperCase();
  }

  static String? _optionalString(
    Object? value,
  ) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : result;
  }

  static String? _optionalCode(
    Object? value,
  ) {
    final String? result = _optionalString(value);

    return result?.toUpperCase();
  }

  static String? _normalizedOptionalString(
    String? value,
  ) {
    final String result = value?.trim() ?? '';

    return result.isEmpty ? null : result;
  }

  static String? _normalizedOptionalCode(
    String? value,
  ) {
    return _normalizedOptionalString(value)?.toUpperCase();
  }

  static double _positiveNumber(
    Object? value,
    String field,
  ) {
    final double? result = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    if (result == null || result <= 0) {
      throw FormatException(
        '$field must be greater than zero.',
      );
    }

    return result;
  }

  static double _nonNegativeNumber(
    Object? value,
    String field,
  ) {
    final double? result = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    if (result == null || result < 0) {
      throw FormatException(
        '$field must be zero or greater.',
      );
    }

    return result;
  }

  static double? _optionalNonNegativeNumber(
    Object? value,
    String field,
  ) {
    if (value == null) {
      return null;
    }

    final String rawValue = value.toString().trim();

    if (rawValue.isEmpty) {
      return null;
    }

    return _nonNegativeNumber(
      value,
      field,
    );
  }

  static int _nonNegativeInteger(
    Object? value,
    String field,
  ) {
    final int? result =
        value is int ? value : int.tryParse(value?.toString() ?? '');

    if (result == null || result < 0) {
      throw FormatException(
        '$field must be zero or greater.',
      );
    }

    return result;
  }

  static bool _requiredBool(
    Object? value,
    String field,
  ) {
    if (value is bool) {
      return value;
    }

    throw FormatException(
      '$field must be a boolean.',
    );
  }

  static bool _sqliteBool(
    Object? value,
    String field,
  ) {
    if (value == 1 || value == true) {
      return true;
    }

    if (value == 0 || value == false) {
      return false;
    }

    throw FormatException(
      '$field must be 0 or 1.',
    );
  }

  static DateTime _requiredDateTime(
    Object? value,
    String field,
  ) {
    final DateTime? result = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (result == null) {
      throw FormatException(
        '$field must be a valid date.',
      );
    }

    return result;
  }

  static DateTime? _optionalDateTime(
    Object? value,
  ) {
    final String result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      return null;
    }

    final DateTime? date = DateTime.tryParse(result);

    if (date == null) {
      throw FormatException(
        'The optional date must be a valid date.',
      );
    }

    return date;
  }
}
