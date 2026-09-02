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
    recipe.validate();

    final List<Map<String, Object?>> existingRows = await database.query(
      'recipe_master',
      columns: const <String>['id'],
      where: 'id = ?',
      whereArgs: <Object?>[
        recipe.id.trim(),
      ],
      limit: 1,
    );

    if (existingRows.isEmpty) {
      throw StateError(
        'The Recipe record was not found.',
      );
    }

    final Batch batch = database.batch();

    batch.update(
      'recipe_master',
      recipe.toSqlite(),
      where: 'id = ?',
      whereArgs: <Object?>[
        recipe.id.trim(),
      ],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    batch.delete(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: <Object?>[
        recipe.id.trim(),
      ],
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

  Future<void> deleteRecipe(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    final String normalizedId = recipeId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final int deleted = await database.delete(
      'recipe_master',
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
    );

    if (deleted == 0) {
      throw StateError(
        'The Recipe record was not found.',
      );
    }
  }

  Future<Recipe?> getRecipeById(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    final String normalizedId = recipeId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final List<Map<String, Object?>> headerRows = await database.query(
      'recipe_master',
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
      limit: 1,
    );

    if (headerRows.isEmpty) {
      return null;
    }

    final List<RecipeIngredient> ingredients = await _getIngredientsByRecipeId(
      database,
      normalizedId,
    );

    return Recipe.fromSqlite(
      headerRows.first,
    ).copyWith(
      ingredients: ingredients,
    );
  }

  Future<List<Recipe>> getRecipes(
    DatabaseExecutor database,
  ) async {
    final List<Map<String, Object?>> headerRows = await database.query(
      'recipe_master',
      orderBy: '''
        recipe_name COLLATE NOCASE,
        recipe_code
      ''',
    );

    final List<Recipe> recipes = <Recipe>[];

    for (final Map<String, Object?> header in headerRows) {
      final Recipe recipe = Recipe.fromSqlite(header);

      final List<RecipeIngredient> ingredients =
          await _getIngredientsByRecipeId(
        database,
        recipe.id,
      );

      recipes.add(
        recipe.copyWith(
          ingredients: ingredients,
        ),
      );
    }

    return List<Recipe>.unmodifiable(
      recipes,
    );
  }

  Future<List<RecipeIngredient>> _getIngredientsByRecipeId(
    DatabaseExecutor database,
    String recipeId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: <Object?>[
        recipeId.trim(),
      ],
      orderBy: '''
        ingredient_name COLLATE NOCASE,
        id
      ''',
    );

    return rows
        .map(
          RecipeIngredient.fromSqlite,
        )
        .toList(growable: false);
  }
}
