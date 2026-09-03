import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:sqflite/sqflite.dart';

class RecipeRepository {
  final RecipeDao recipeDao;

  const RecipeRepository({
    this.recipeDao = const RecipeDao(),
  });

  Future<List<Recipe>> getRecipes() async {
    final Database database = await AppDatabase.instance.database;

    return recipeDao.getRecipes(
      database,
    );
  }

  Future<Recipe?> getRecipeById(
    String recipeId,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return recipeDao.getRecipeById(
      database,
      recipeId,
    );
  }

  Future<bool> recipeCodeExists(
    String recipeCode, {
    String? excludingId,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return recipeDao.recipeCodeExists(
      database,
      recipeCode,
      excludingId: excludingId,
    );
  }

  Future<Recipe> createRecipe(
    Recipe recipe, {
    required String currentUserId,
  }) async {
    recipe.validate();

    final String authenticatedUserId = _requireAuthenticatedUserId(
      currentUserId,
    );

    final Database database = await AppDatabase.instance.database;

    return database.transaction(
      (Transaction transaction) async {
        final Recipe? existing = await recipeDao.findByIdIncludingDeleted(
          transaction,
          recipe.id,
        );

        if (existing != null) {
          if (existing.isDeleted) {
            throw StateError(
              'A deleted Recipe cannot be recreated '
              'with the same ID.',
            );
          }

          throw StateError(
            'A Recipe with this ID already exists.',
          );
        }

        final bool duplicate = await recipeDao.recipeCodeExists(
          transaction,
          recipe.recipeCode,
        );

        if (duplicate) {
          throw StateError(
            'A Recipe with code '
            '${recipe.recipeCode.trim().toUpperCase()} '
            'already exists.',
          );
        }

        final DateTime now = DateTime.now().toUtc();

        final Recipe normalized = recipe.copyWith(
          recipeCode: recipe.recipeCode.trim().toUpperCase(),
          recipeName: recipe.recipeName.trim(),
          yieldUnitCode: recipe.yieldUnitCode.trim().toUpperCase(),
          active: true,
          createdAt: now,
          updatedAt: now,
          createdBy: authenticatedUserId,
          updatedBy: authenticatedUserId,
          syncStatus: MasterSyncStatus.pending,
          serverVersion: 0,
          clearDeletedAt: true,
        );

        normalized.validate();

        await recipeDao.insertRecipe(
          transaction,
          normalized,
        );

        return normalized;
      },
    );
  }

  Future<Recipe> updateRecipe(
    Recipe recipe, {
    required String currentUserId,
  }) async {
    recipe.validate();

    final String authenticatedUserId = _requireAuthenticatedUserId(
      currentUserId,
    );

    final Database database = await AppDatabase.instance.database;

    return database.transaction(
      (Transaction transaction) async {
        final Recipe? existing = await recipeDao.findByIdIncludingDeleted(
          transaction,
          recipe.id,
        );

        if (existing == null) {
          throw StateError(
            'The Recipe record was not found.',
          );
        }

        if (existing.isDeleted) {
          throw StateError(
            'A deleted Recipe cannot be edited.',
          );
        }

        final bool duplicate = await recipeDao.recipeCodeExists(
          transaction,
          recipe.recipeCode,
          excludingId: recipe.id,
        );

        if (duplicate) {
          throw StateError(
            'A Recipe with code '
            '${recipe.recipeCode.trim().toUpperCase()} '
            'already exists.',
          );
        }

        final Recipe normalized = recipe.copyWith(
          recipeCode: recipe.recipeCode.trim().toUpperCase(),
          recipeName: recipe.recipeName.trim(),
          yieldUnitCode: recipe.yieldUnitCode.trim().toUpperCase(),
          createdAt: existing.createdAt,
          createdBy: existing.createdBy,
          updatedAt: DateTime.now().toUtc(),
          updatedBy: authenticatedUserId,
          syncStatus: MasterSyncStatus.pending,
          serverVersion: existing.serverVersion,
          clearDeletedAt: true,
        );

        normalized.validate();

        await recipeDao.updateRecipe(
          transaction,
          normalized,
        );

        return normalized;
      },
    );
  }

  Future<void> deleteRecipe(
    Recipe recipe, {
    required String currentUserId,
  }) async {
    final String authenticatedUserId = _requireAuthenticatedUserId(
      currentUserId,
    );

    final Database database = await AppDatabase.instance.database;

    await database.transaction(
      (Transaction transaction) async {
        final Recipe? existing = await recipeDao.findByIdIncludingDeleted(
          transaction,
          recipe.id,
        );

        if (existing == null) {
          throw StateError(
            'The Recipe record was not found.',
          );
        }

        if (existing.isDeleted) {
          throw StateError(
            'The Recipe record was already deleted.',
          );
        }

        await recipeDao.softDelete(
          transaction,
          recipe.id,
          updatedBy: authenticatedUserId,
          deletedAt: DateTime.now().toUtc(),
        );
      },
    );
  }

  String _requireAuthenticatedUserId(
    String currentUserId,
  ) {
    final String result = currentUserId.trim();

    if (result.isEmpty) {
      throw const FormatException(
        'Authenticated user identity is required.',
      );
    }

    return result;
  }
}
