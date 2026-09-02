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

  double get extendedCost => quantityRequired * costPerUsageUnit;
}
