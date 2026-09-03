import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String repositorySource;
  late String daoSource;

  setUpAll(() {
    repositorySource = File(
      'lib/data/repositories/'
      'recipe_repository.dart',
    ).readAsStringSync();

    daoSource = File(
      'lib/data/local/daos/recipe_dao.dart',
    ).readAsStringSync();
  });

  group('Recipe Repository public API', () {
    test('provides Recipe listing', () {
      expect(
        repositorySource,
        contains(
          'Future<List<Recipe>> getRecipes(',
        ),
      );

      expect(
        repositorySource,
        contains('recipeDao.getRecipes('),
      );
    });

    test('provides Recipe lookup', () {
      expect(
        repositorySource,
        contains(
          'Future<Recipe?> getRecipeById(',
        ),
      );

      expect(
        repositorySource,
        contains('recipeDao.getRecipeById('),
      );
    });

    test('provides Recipe create operation', () {
      expect(
        repositorySource,
        contains(
          'Future<Recipe> createRecipe(',
        ),
      );

      expect(
        repositorySource,
        contains('recipeDao.insertRecipe('),
      );
    });

    test('provides Recipe update operation', () {
      expect(
        repositorySource,
        contains(
          'Future<Recipe> updateRecipe(',
        ),
      );

      expect(
        repositorySource,
        contains('recipeDao.updateRecipe('),
      );
    });

    test('provides Recipe deletion', () {
      expect(
        repositorySource,
        contains(
          'Future<void> deleteRecipe(',
        ),
      );

      expect(
        repositorySource,
        contains('recipeDao.softDelete('),
      );
    });

    test('provides Recipe Code lookup', () {
      expect(
        repositorySource,
        contains(
          'Future<bool> recipeCodeExists(',
        ),
      );

      expect(
        repositorySource,
        contains('recipeDao.recipeCodeExists('),
      );
    });
  });

  group('Recipe Repository safeguards', () {
    test('uses AppDatabase singleton', () {
      expect(
        repositorySource,
        contains(
          'AppDatabase.instance.database',
        ),
      );
    });

    test('uses transactions for local changes', () {
      expect(
        repositorySource,
        contains('database.transaction('),
      );
    });

    test('requires authenticated identity', () {
      expect(
        repositorySource,
        contains(
          '_requireAuthenticatedUserId(',
        ),
      );

      expect(
        repositorySource,
        contains(
          'Authenticated user identity is required.',
        ),
      );
    });

    test('validates Recipe models', () {
      expect(
        repositorySource,
        contains('recipe.validate()'),
      );

      expect(
        repositorySource,
        contains('normalized.validate()'),
      );
    });

    test('checks deleted Recipe records', () {
      expect(
        repositorySource,
        contains(
          'findByIdIncludingDeleted(',
        ),
      );

      expect(
        repositorySource,
        contains(
          'A deleted Recipe cannot be edited.',
        ),
      );
    });

    test('prevents duplicate Recipe Codes', () {
      expect(
        repositorySource,
        contains(
          'recipeDao.recipeCodeExists(',
        ),
      );

      expect(
        repositorySource,
        contains('already exists.'),
      );
    });

    test('normalizes Recipe identity fields', () {
      expect(
        repositorySource,
        contains(
          'recipe.recipeCode.trim().toUpperCase()',
        ),
      );

      expect(
        repositorySource,
        contains(
          'recipe.recipeName.trim()',
        ),
      );

      expect(
        repositorySource,
        contains(
          'recipe.yieldUnitCode',
        ),
      );
    });

    test('records authenticated audit fields', () {
      expect(
        repositorySource,
        contains(
          'createdBy: authenticatedUserId',
        ),
      );

      expect(
        repositorySource,
        contains(
          'updatedBy: authenticatedUserId',
        ),
      );
    });

    test('preserves creation audit when editing', () {
      expect(
        repositorySource,
        contains(
          'createdAt: existing.createdAt',
        ),
      );

      expect(
        repositorySource,
        contains(
          'createdBy: existing.createdBy',
        ),
      );
    });

    test('marks local changes Pending', () {
      expect(
        repositorySource,
        contains(
          'syncStatus: MasterSyncStatus.pending',
        ),
      );
    });

    test('preserves server version when editing', () {
      expect(
        repositorySource,
        contains(
          'existing.serverVersion',
        ),
      );
    });
  });

  group('Recipe DAO Repository support', () {
    test('supports deleted-record lookup', () {
      expect(
        daoSource,
        contains(
          'Future<Recipe?> '
          'findByIdIncludingDeleted(',
        ),
      );
    });

    test('supports Recipe Code duplicate checks', () {
      expect(
        daoSource,
        contains(
          'Future<bool> recipeCodeExists(',
        ),
      );

      expect(
        daoSource,
        contains(
          'recipe_code = ?',
        ),
      );

      expect(
        daoSource,
        contains(
          'excludingId',
        ),
      );
    });
  });
}
