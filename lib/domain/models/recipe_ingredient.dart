class RecipeIngredient {
  final String id;
  final String recipeId;

  final String ingredientId;
  final String ingredientSku;
  final String ingredientName;

  final String usageUnitCode;

  final double quantityRequired;
  final double costPerUsageUnit;

  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    required this.ingredientSku,
    required this.ingredientName,
    required this.usageUnitCode,
    required this.quantityRequired,
    required this.costPerUsageUnit,
  });

  double get extendedCost {
    return quantityRequired * costPerUsageUnit;
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException(
        'Recipe Ingredient ID is required.',
      );
    }

    if (recipeId.trim().isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    if (ingredientId.trim().isEmpty) {
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
        'Ingredient Name is required.',
      );
    }

    if (usageUnitCode.trim().isEmpty) {
      throw const FormatException(
        'Usage Unit is required.',
      );
    }

    if (!quantityRequired.isFinite || quantityRequired <= 0) {
      throw const FormatException(
        'Quantity Required must be greater than zero.',
      );
    }

    if (!costPerUsageUnit.isFinite || costPerUsageUnit < 0) {
      throw const FormatException(
        'Cost per Usage Unit cannot be negative.',
      );
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'recipe_id': recipeId.trim(),
      'ingredient_id': ingredientId.trim(),
      'ingredient_sku': ingredientSku.trim().toUpperCase(),
      'ingredient_name': ingredientName.trim(),
      'usage_unit_code': usageUnitCode.trim().toUpperCase(),
      'quantity_required': quantityRequired,
      'cost_per_usage_unit': costPerUsageUnit,
    };
  }

  factory RecipeIngredient.fromSqlite(
    Map<String, Object?> map,
  ) {
    final RecipeIngredient ingredient = RecipeIngredient(
      id: _requiredString(
        map['id'],
        'id',
      ),
      recipeId: _requiredString(
        map['recipe_id'],
        'recipe_id',
      ),
      ingredientId: _requiredString(
        map['ingredient_id'],
        'ingredient_id',
      ),
      ingredientSku: _requiredString(
        map['ingredient_sku'],
        'ingredient_sku',
      ).toUpperCase(),
      ingredientName: _requiredString(
        map['ingredient_name'],
        'ingredient_name',
      ),
      usageUnitCode: _requiredString(
        map['usage_unit_code'],
        'usage_unit_code',
      ).toUpperCase(),
      quantityRequired: _requiredDouble(
        map['quantity_required'],
        'quantity_required',
      ),
      costPerUsageUnit: _requiredDouble(
        map['cost_per_usage_unit'],
        'cost_per_usage_unit',
      ),
    );

    ingredient.validate();
    return ingredient;
  }

  RecipeIngredient copyWith({
    String? id,
    String? recipeId,
    String? ingredientId,
    String? ingredientSku,
    String? ingredientName,
    String? usageUnitCode,
    double? quantityRequired,
    double? costPerUsageUnit,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientSku: ingredientSku ?? this.ingredientSku,
      ingredientName: ingredientName ?? this.ingredientName,
      usageUnitCode: usageUnitCode ?? this.usageUnitCode,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      costPerUsageUnit: costPerUsageUnit ?? this.costPerUsageUnit,
    );
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

double _requiredDouble(
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
