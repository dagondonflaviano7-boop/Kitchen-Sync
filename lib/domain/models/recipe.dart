import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';

enum RecipeCategory {
  mainDish,
  sideDish,
  beverage,
  dessert,
  sauce,
  ingredientPrep,
}

class Recipe {
  final String id;
  final String recipeCode;
  final String recipeName;
  final RecipeCategory category;
  final double yieldQuantity;
  final String yieldUnitCode;
  final bool active;
  final List<RecipeIngredient> ingredients;

  const Recipe({
    required this.id,
    required this.recipeCode,
    required this.recipeName,
    required this.category,
    required this.yieldQuantity,
    required this.yieldUnitCode,
    required this.active,
    required this.ingredients,
  });

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException('Recipe ID is required.');
    }

    if (recipeCode.trim().isEmpty) {
      throw const FormatException('Recipe Code is required.');
    }

    if (recipeName.trim().isEmpty) {
      throw const FormatException(
        'Recipe Name is required.',
      );
    }

    if (!yieldQuantity.isFinite || yieldQuantity <= 0) {
      throw const FormatException(
        'Yield Quantity must be greater than zero.',
      );
    }

    if (yieldUnitCode.trim().isEmpty) {
      throw const FormatException(
        'Yield Unit is required.',
      );
    }

    final Set<String> ingredientIds = <String>{};

    for (final RecipeIngredient ingredient in ingredients) {
      ingredient.validate();

      if (ingredient.recipeId.trim() != id.trim()) {
        throw const FormatException(
          'Every Recipe Ingredient must belong '
          'to the Recipe being saved.',
        );
      }

      final String ingredientId = ingredient.ingredientId.trim();

      if (!ingredientIds.add(ingredientId)) {
        throw const FormatException(
          'The same Ingredient cannot be added '
          'to a Recipe more than once.',
        );
      }
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id,
      'recipe_code': recipeCode,
      'recipe_name': recipeName,
      'category': category.name,
      'yield_quantity': yieldQuantity,
      'yield_unit_code': yieldUnitCode,
      'active': active ? 1 : 0,
    };
  }

  factory Recipe.fromSqlite(
    Map<String, Object?> map,
  ) {
    return Recipe(
      id: map['id'].toString(),
      recipeCode: map['recipe_code'].toString(),
      recipeName: map['recipe_name'].toString(),
      category: RecipeCategory.values.firstWhere(
        (value) => value.name == map['category'],
      ),
      yieldQuantity: (map['yield_quantity'] as num).toDouble(),
      yieldUnitCode: map['yield_unit_code'].toString(),
      active: (map['active'] as int) == 1,
      ingredients: const [],
    );
  }

  Recipe copyWith({
    String? id,
    String? recipeCode,
    String? recipeName,
    RecipeCategory? category,
    double? yieldQuantity,
    String? yieldUnitCode,
    bool? active,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      recipeCode: recipeCode ?? this.recipeCode,
      recipeName: recipeName ?? this.recipeName,
      category: category ?? this.category,
      yieldQuantity: yieldQuantity ?? this.yieldQuantity,
      yieldUnitCode: yieldUnitCode ?? this.yieldUnitCode,
      active: active ?? this.active,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  double get totalRecipeCost {
    return ingredients.fold(
      0,
      (double total, RecipeIngredient ingredient) {
        return total + ingredient.extendedCost;
      },
    );
  }

  double get costPerServing {
    if (yieldQuantity <= 0) {
      return 0;
    }

    return totalRecipeCost / yieldQuantity;
  }
}
