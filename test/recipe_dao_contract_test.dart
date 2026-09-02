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

  group('RecipeDao read implementation', () {
    test('queries Recipe Master header', () {
      expect(
        source,
        contains(
          "database.query(\n      'recipe_master'",
        ),
      );
    });

    test('queries Recipe Ingredient lines', () {
      expect(
        source,
        contains(
          "database.query(\n      'recipe_ingredients'",
        ),
      );
    });

    test('rebuilds Recipe from SQLite', () {
      expect(
        source,
        contains(
          'Recipe.fromSqlite(',
        ),
      );

      expect(
        source,
        contains(
          'RecipeIngredient.fromSqlite',
        ),
      );
    });

    test('attaches Ingredient lines to Recipe', () {
      expect(
        source,
        contains(
          'ingredients: ingredients',
        ),
      );
    });

    test('sorts Recipes by name and code', () {
      expect(
        source,
        contains(
          'recipe_name COLLATE NOCASE',
        ),
      );

      expect(
        source,
        contains('recipe_code'),
      );
    });
  });

  group('RecipeDao update implementation', () {
    test('validates Recipe before update', () {
      final int updatePosition = source.indexOf(
        'Future<void> updateRecipe(',
      );

      final int validationPosition = source.indexOf(
        'recipe.validate()',
        updatePosition,
      );

      expect(
        validationPosition,
        greaterThan(updatePosition),
      );
    });

    test('checks that Recipe exists', () {
      expect(
        source,
        contains(
          'The Recipe record was not found.',
        ),
      );
    });

    test('updates Recipe Master header', () {
      expect(
        source,
        contains('batch.update('),
      );

      expect(
        source,
        contains("'recipe_master'"),
      );
    });

    test('deletes previous Ingredient lines', () {
      expect(
        source,
        contains('batch.delete('),
      );

      expect(
        source,
        contains("'recipe_ingredients'"),
      );
    });

    test('inserts replacement lines', () {
      expect(
        source,
        contains('ingredient.toSqlite()'),
      );
    });

    test('uses abort conflict handling', () {
      expect(
        source,
        contains(
          'ConflictAlgorithm.abort',
        ),
      );
    });

    test('stops the update on any error', () {
      expect(
        source,
        contains(
          'continueOnError: false',
        ),
      );
    });
  });

  group('RecipeDao soft-delete implementation', () {
    test('deleteRecipe delegates to softDelete', () {
      final int deletePosition = source.indexOf(
        'Future<void> deleteRecipe(',
      );

      final int softDeleteCallPosition = source.indexOf(
        'await softDelete(',
        deletePosition,
      );

      expect(
        deletePosition,
        greaterThanOrEqualTo(0),
      );

      expect(
        softDeleteCallPosition,
        greaterThan(deletePosition),
      );
    });

    test('provides explicit softDelete operation', () {
      expect(
        source,
        contains(
          'Future<void> softDelete(',
        ),
      );

      expect(
        source,
        contains(
          'required String updatedBy',
        ),
      );
    });

    test('normalizes Recipe and user IDs', () {
      final int softDeletePosition = source.indexOf(
        'Future<void> softDelete(',
      );

      final String method = source.substring(
        softDeletePosition,
      );

      expect(
        method,
        contains('recipeId.trim()'),
      );

      expect(
        method,
        contains('updatedBy.trim()'),
      );
    });

    test('rejects blank Recipe ID', () {
      expect(
        source,
        contains(
          "'Recipe ID is required.'",
        ),
      );
    });

    test('rejects blank Updated By value', () {
      expect(
        source,
        contains(
          "'Updated By is required.'",
        ),
      );
    });

    test('updates Recipe tombstone fields', () {
      final int softDeletePosition = source.indexOf(
        'Future<void> softDelete(',
      );

      final String method = source.substring(
        softDeletePosition,
      );

      expect(
        method,
        contains('database.update('),
      );

      expect(
        method,
        contains("'recipe_master'"),
      );

      expect(
        method,
        contains("'active': 0"),
      );

      expect(
        method,
        contains("'updated_at': timestamp"),
      );

      expect(
        method,
        contains(
          "'updated_by': normalizedUserId",
        ),
      );

      expect(
        method,
        contains(
          "'sync_status': 'PENDING'",
        ),
      );

      expect(
        method,
        contains("'deleted_at': timestamp"),
      );
    });

    test('updates only a non-deleted Recipe', () {
      final int softDeletePosition = source.indexOf(
        'Future<void> softDelete(',
      );

      final String method = source.substring(
        softDeletePosition,
      );

      expect(
        method,
        contains('id = ?'),
      );

      expect(
        method,
        contains('deleted_at IS NULL'),
      );

      expect(
        method,
        contains('normalizedId'),
      );
    });

    test('rejects missing or already deleted Recipe', () {
      expect(
        source,
        contains('if (updated == 0)'),
      );

      expect(
        source,
        contains(
          'The Recipe record was not found ',
        ),
      );

      expect(
        source,
        contains(
          'or was already deleted.',
        ),
      );
    });

    test('does not physically delete Recipe header', () {
      final int deletePosition = source.indexOf(
        'Future<void> deleteRecipe(',
      );

      final int readPosition = source.indexOf(
        'Future<Recipe?> getRecipeById(',
        deletePosition,
      );

      final String deleteMethods = source.substring(
        deletePosition,
        readPosition,
      );

      expect(
        deleteMethods,
        isNot(
          contains('database.delete('),
        ),
      );
    });
  });
}
