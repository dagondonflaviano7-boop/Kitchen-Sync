import 'package:kitchen_sync/domain/models/recipe.dart';

class RecipeDao {
  Future<void> insertRecipe(
    Recipe recipe,
  ) async {}

  Future<void> updateRecipe(
    Recipe recipe,
  ) async {}

  Future<void> deleteRecipe(
    String recipeId,
  ) async {}

  Future<Recipe?> getRecipeById(
    String recipeId,
  ) async {
    return null;
  }

  Future<List<Recipe>> getRecipes() async {
    return <Recipe>[];
  }
}
