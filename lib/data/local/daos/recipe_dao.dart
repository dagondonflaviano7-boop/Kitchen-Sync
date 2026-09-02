import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:sqflite/sqflite.dart';

class RecipeDao {
  const RecipeDao();

  Future<void> insertRecipe(
    DatabaseExecutor database,
    Recipe recipe,
  ) async {
    recipe.validate();

    final Map<String, Object?> header = recipe.toSqlite();

    final Batch batch = database.batch();

    batch.insert(
      'recipe_master',
      header,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    for (final RecipeIngredient ingredient in recipe.ingredients) {
      ingredient.validate();

      batch.insert(
        'recipe_ingredients',
        ingredient.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }

    await batch.commit(
      noResult: true,
      continueOnError: false,
    );
  }

  Future<void> updateRecipe(
    DatabaseExecutor database,
    Recipe recipe,
  ) async {
    throw UnimplementedError(
      'Recipe update will be implemented '
      'after insertRecipe validation.',
    );
  }

  Future<void> deleteRecipe(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    throw UnimplementedError(
      'Recipe deletion will be implemented '
      'after insertRecipe validation.',
    );
  }

  Future<Recipe?> getRecipeById(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    return null;
  }

  Future<List<Recipe>> getRecipes(
    DatabaseExecutor database,
  ) async {
    return <Recipe>[];
  }
}
