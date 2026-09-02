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

  double get totalRecipeCost {
    return ingredients.fold(
      0,
      (
        double total,
        RecipeIngredient ingredient,
      ) {
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
