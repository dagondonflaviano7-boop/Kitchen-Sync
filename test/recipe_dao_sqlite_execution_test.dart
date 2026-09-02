import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v5.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  const RecipeDao recipeDao = RecipeDao();

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (Database db) async {
          await db.execute(
            'PRAGMA foreign_keys = ON',
          );
        },
        onCreate: (
          Database db,
          int version,
        ) async {
          await db.execute(
            '''
            CREATE TABLE ingredients (
              id TEXT PRIMARY KEY
            )
            ''',
          );

          for (final String statement in migrationV5) {
            await db.execute(statement);
          }
        },
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertSupportingIngredients() async {
    await database.insert(
      'ingredients',
      <String, Object?>{
        'id': 'ingredient-chicken',
      },
    );

    await database.insert(
      'ingredients',
      <String, Object?>{
        'id': 'ingredient-soy-sauce',
      },
    );
  }

  Recipe buildRecipe({
    String id = 'recipe-adobo',
    String recipeCode = 'RCP-ADOBO-001',
    String recipeName = 'Chicken Adobo',
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id,
      recipeCode: recipeCode,
      recipeName: recipeName,
      category: RecipeCategory.mainDish,
      yieldQuantity: 10,
      yieldUnitCode: 'SERVING',
      active: true,
      ingredients: ingredients ??
          const <RecipeIngredient>[
            RecipeIngredient(
              id: 'line-chicken',
              recipeId: 'recipe-adobo',
              ingredientId: 'ingredient-chicken',
              ingredientSku: 'ING-CHICKEN-001',
              ingredientName: 'Chicken',
              usageUnitCode: 'G',
              quantityRequired: 500,
              costPerUsageUnit: 0.25,
            ),
            RecipeIngredient(
              id: 'line-soy-sauce',
              recipeId: 'recipe-adobo',
              ingredientId: 'ingredient-soy-sauce',
              ingredientSku: 'ING-SOY-001',
              ingredientName: 'Soy Sauce',
              usageUnitCode: 'ML',
              quantityRequired: 250,
              costPerUsageUnit: 0.08,
            ),
          ],
    );
  }

  group('RecipeDao SQLite execution', () {
    test(
      'insertRecipe stores Recipe header',
      () async {
        await insertSupportingIngredients();

        final Recipe recipe = buildRecipe();

        await recipeDao.insertRecipe(
          database,
          recipe,
        );

        final List<Map<String, Object?>> rows = await database.query(
          'recipe_master',
          where: 'id = ?',
          whereArgs: <Object?>[
            recipe.id,
          ],
        );

        expect(rows, hasLength(1));

        final Map<String, Object?> row = rows.single;

        expect(
          row['id'],
          'recipe-adobo',
        );

        expect(
          row['recipe_code'],
          'RCP-ADOBO-001',
        );

        expect(
          row['recipe_name'],
          'Chicken Adobo',
        );

        expect(
          row['category'],
          'mainDish',
        );

        expect(
          row['yield_quantity'],
          10.0,
        );

        expect(
          row['yield_unit_code'],
          'SERVING',
        );

        expect(
          row['active'],
          1,
        );
      },
    );

    test(
      'insertRecipe stores all Ingredient lines',
      () async {
        await insertSupportingIngredients();

        final Recipe recipe = buildRecipe();

        await recipeDao.insertRecipe(
          database,
          recipe,
        );

        final List<Map<String, Object?>> rows = await database.query(
          'recipe_ingredients',
          where: 'recipe_id = ?',
          whereArgs: const <Object?>[
            'recipe-adobo',
          ],
          orderBy: 'id',
        );

        expect(rows, hasLength(2));

        final Map<String, Object?> chicken = rows.firstWhere(
          (Map<String, Object?> row) {
            return row['id'] == 'line-chicken';
          },
        );

        expect(
          chicken['ingredient_id'],
          'ingredient-chicken',
        );

        expect(
          chicken['ingredient_sku'],
          'ING-CHICKEN-001',
        );

        expect(
          chicken['ingredient_name'],
          'Chicken',
        );

        expect(
          chicken['usage_unit_code'],
          'G',
        );

        expect(
          chicken['quantity_required'],
          500.0,
        );

        expect(
          chicken['cost_per_usage_unit'],
          0.25,
        );

        final Map<String, Object?> soySauce = rows.firstWhere(
          (Map<String, Object?> row) {
            return row['id'] == 'line-soy-sauce';
          },
        );

        expect(
          soySauce['ingredient_id'],
          'ingredient-soy-sauce',
        );

        expect(
          soySauce['quantity_required'],
          250.0,
        );

        expect(
          soySauce['cost_per_usage_unit'],
          0.08,
        );
      },
    );

    test(
      'insertRecipe preserves calculated costs',
      () async {
        await insertSupportingIngredients();

        final Recipe recipe = buildRecipe();

        await recipeDao.insertRecipe(
          database,
          recipe,
        );

        expect(
          recipe.totalRecipeCost,
          145,
        );

        expect(
          recipe.costPerServing,
          14.5,
        );
      },
    );

    test(
      'insertRecipe rolls back header when '
      'an Ingredient foreign key fails',
      () async {
        await database.insert(
          'ingredients',
          <String, Object?>{
            'id': 'ingredient-chicken',
          },
        );

        final Recipe recipe = buildRecipe(
          id: 'recipe-invalid',
          recipeCode: 'RCP-INVALID-001',
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              id: 'line-valid',
              recipeId: 'recipe-invalid',
              ingredientId: 'ingredient-chicken',
              ingredientSku: 'ING-CHICKEN-001',
              ingredientName: 'Chicken',
              usageUnitCode: 'G',
              quantityRequired: 100,
              costPerUsageUnit: 0.25,
            ),
            RecipeIngredient(
              id: 'line-invalid',
              recipeId: 'recipe-invalid',
              ingredientId: 'ingredient-missing',
              ingredientSku: 'ING-MISSING-001',
              ingredientName: 'Missing Ingredient',
              usageUnitCode: 'G',
              quantityRequired: 50,
              costPerUsageUnit: 0.10,
            ),
          ],
        );

        await expectLater(
          recipeDao.insertRecipe(
            database,
            recipe,
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );

        final List<Map<String, Object?>> headerRows = await database.query(
          'recipe_master',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'recipe-invalid',
          ],
        );

        final List<Map<String, Object?>> lineRows = await database.query(
          'recipe_ingredients',
          where: 'recipe_id = ?',
          whereArgs: const <Object?>[
            'recipe-invalid',
          ],
        );

        expect(headerRows, isEmpty);
        expect(lineRows, isEmpty);
      },
    );

    test(
      'insertRecipe rejects duplicate Recipe code',
      () async {
        await insertSupportingIngredients();

        final Recipe first = buildRecipe();

        await recipeDao.insertRecipe(
          database,
          first,
        );

        final Recipe duplicate = buildRecipe(
          id: 'recipe-adobo-copy',
          recipeCode: first.recipeCode,
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              id: 'line-copy-chicken',
              recipeId: 'recipe-adobo-copy',
              ingredientId: 'ingredient-chicken',
              ingredientSku: 'ING-CHICKEN-001',
              ingredientName: 'Chicken',
              usageUnitCode: 'G',
              quantityRequired: 400,
              costPerUsageUnit: 0.25,
            ),
          ],
        );

        await expectLater(
          recipeDao.insertRecipe(
            database,
            duplicate,
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );

        final List<Map<String, Object?>> rows = await database.query(
          'recipe_master',
        );

        expect(rows, hasLength(1));
        expect(
          rows.single['id'],
          first.id,
        );
      },
    );

    test(
      'getRecipeById returns complete Recipe',
      () async {
        await insertSupportingIngredients();

        final Recipe original = buildRecipe();

        await recipeDao.insertRecipe(
          database,
          original,
        );

        final Recipe? loaded = await recipeDao.getRecipeById(
          database,
          original.id,
        );

        expect(loaded, isNotNull);
        expect(loaded!.id, original.id);
        expect(
          loaded.recipeCode,
          original.recipeCode,
        );
        expect(
          loaded.recipeName,
          original.recipeName,
        );
        expect(
          loaded.category,
          RecipeCategory.mainDish,
        );
        expect(loaded.yieldQuantity, 10);
        expect(
          loaded.yieldUnitCode,
          'SERVING',
        );
        expect(loaded.active, isTrue);
        expect(loaded.ingredients, hasLength(2));
      },
    );

    test(
      'getRecipeById restores Ingredient lines '
      'and calculated costs',
      () async {
        await insertSupportingIngredients();

        final Recipe original = buildRecipe();

        await recipeDao.insertRecipe(
          database,
          original,
        );

        final Recipe loaded = (await recipeDao.getRecipeById(
          database,
          original.id,
        ))!;

        expect(
          loaded.ingredients.map(
            (RecipeIngredient line) {
              return line.ingredientName;
            },
          ),
          containsAll(
            <String>[
              'Chicken',
              'Soy Sauce',
            ],
          ),
        );

        expect(
          loaded.totalRecipeCost,
          145,
        );

        expect(
          loaded.costPerServing,
          14.5,
        );
      },
    );

    test(
      'getRecipeById returns null for unknown ID',
      () async {
        final Recipe? loaded = await recipeDao.getRecipeById(
          database,
          'recipe-not-found',
        );

        expect(loaded, isNull);
      },
    );

    test(
      'getRecipeById rejects blank ID',
      () async {
        await expectLater(
          recipeDao.getRecipeById(
            database,
            '   ',
          ),
          throwsA(
            isA<FormatException>(),
          ),
        );
      },
    );

    test(
      'getRecipes returns complete Recipes '
      'sorted by name',
      () async {
        await insertSupportingIngredients();

        final Recipe adobo = buildRecipe();

        final Recipe bistek = buildRecipe(
          id: 'recipe-bistek',
          recipeCode: 'RCP-BISTEK-001',
          recipeName: 'Beef Steak',
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              id: 'line-bistek',
              recipeId: 'recipe-bistek',
              ingredientId: 'ingredient-chicken',
              ingredientSku: 'ING-CHICKEN-001',
              ingredientName: 'Chicken',
              usageUnitCode: 'G',
              quantityRequired: 200,
              costPerUsageUnit: 0.25,
            ),
          ],
        );

        await recipeDao.insertRecipe(
          database,
          adobo,
        );

        await recipeDao.insertRecipe(
          database,
          bistek,
        );

        final List<Recipe> recipes = await recipeDao.getRecipes(
          database,
        );

        expect(recipes, hasLength(2));

        expect(
          recipes.first.recipeName,
          'Beef Steak',
        );

        expect(
          recipes.last.recipeName,
          'Chicken Adobo',
        );

        expect(
          recipes.first.ingredients,
          hasLength(1),
        );

        expect(
          recipes.last.ingredients,
          hasLength(2),
        );
      },
    );

    test(
      'getRecipes returns an unmodifiable list',
      () async {
        final List<Recipe> recipes = await recipeDao.getRecipes(
          database,
        );

        expect(
          () => recipes.add(
            buildRecipe(),
          ),
          throwsUnsupportedError,
        );
      },
    );
  });
}
