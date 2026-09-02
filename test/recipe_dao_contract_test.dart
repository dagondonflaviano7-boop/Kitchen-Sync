import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/local/daos/recipe_dao.dart',
    ).readAsStringSync();
  });

  group('RecipeDao Contract', () {
    test('contains RecipeDao class', () {
      expect(
        source,
        contains('class RecipeDao'),
      );
    });

    test('contains insertRecipe', () {
      expect(
        source,
        contains('insertRecipe('),
      );
    });

    test('contains updateRecipe', () {
      expect(
        source,
        contains('updateRecipe('),
      );
    });

    test('contains deleteRecipe', () {
      expect(
        source,
        contains('deleteRecipe('),
      );
    });

    test('contains getRecipeById', () {
      expect(
        source,
        contains('getRecipeById('),
      );
    });

    test('contains getRecipes', () {
      expect(
        source,
        contains('getRecipes('),
      );
    });
  });

  group('RecipeDao insert implementation', () {
    test('uses DatabaseExecutor', () {
      expect(
        source,
        contains('DatabaseExecutor database'),
      );
    });

    test('validates Recipe before insertion', () {
      expect(
        source,
        contains('recipe.validate()'),
      );
    });

    test('inserts Recipe header', () {
      expect(
        source,
        contains("'recipe_master'"),
      );
    });

    test('inserts Recipe Ingredient lines', () {
      expect(
        source,
        contains("'recipe_ingredients'"),
      );

      expect(
        source,
        contains('ingredient.toSqlite()'),
      );
    });

    test('uses one SQLite batch', () {
      expect(
        source,
        contains('final Batch batch'),
      );

      expect(
        source,
        contains('database.batch()'),
      );

      expect(
        source,
        contains('batch.commit('),
      );
    });

    test('does not continue after an error', () {
      expect(
        source,
        contains('continueOnError: false'),
      );
    });

    test('does not silently replace Recipes', () {
      expect(
        source,
        contains('ConflictAlgorithm.abort'),
      );
    });
  });
}
