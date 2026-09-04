import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

void main() {
  Recipe createRecipe({
    DateTime? deletedAt,
    bool active = true,
  }) {
    return Recipe(
      id: 'recipe-adobo',
      recipeCode: 'RCP-ADOBO-001',
      recipeName: 'Chicken Adobo',
      category: RecipeCategory.mainDish,
      yieldQuantity: 10,
      yieldUnitCode: 'SERVING',
      active: active,
      ingredients: const <RecipeIngredient>[
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
          id: 'line-soy',
          recipeId: 'recipe-adobo',
          ingredientId: 'ingredient-soy',
          ingredientSku: 'ING-SOY-001',
          ingredientName: 'Soy Sauce',
          usageUnitCode: 'ML',
          quantityRequired: 250,
          costPerUsageUnit: 0.08,
        ),
      ],
      createdAt: DateTime.utc(
        2026,
        9,
        4,
        1,
      ),
      updatedAt: DateTime.utc(
        2026,
        9,
        4,
        2,
      ),
      createdBy: 'user-admin',
      updatedBy: 'user-manager',
      syncStatus: MasterSyncStatus.pending,
      serverVersion: 4,
      deletedAt: deletedAt,
    );
  }

  group('Recipe Firebase mapping', () {
    test('serializes Recipe core fields', () {
      final Map<String, Object?> map = createRecipe().toFirebase();

      expect(map['id'], 'recipe-adobo');
      expect(map['recipeCode'], 'RCP-ADOBO-001');
      expect(map['recipeName'], 'Chicken Adobo');
      expect(map['category'], 'mainDish');
      expect(map['yieldQuantity'], 10);
      expect(map['yieldUnitCode'], 'SERVING');
      expect(map['active'], isTrue);
      expect(map['serverVersion'], 4);
    });

    test('serializes Recipe audit fields', () {
      final Map<String, Object?> map = createRecipe().toFirebase();

      expect(
        map['createdAt'],
        '2026-09-04T01:00:00.000Z',
      );

      expect(
        map['updatedAt'],
        '2026-09-04T02:00:00.000Z',
      );

      expect(map['createdBy'], 'user-admin');
      expect(map['updatedBy'], 'user-manager');
    });

    test('serializes local sync status', () {
      final Map<String, Object?> map = createRecipe().toFirebase();

      expect(map['syncStatus'], 'PENDING');
    });

    test('serializes Ingredient lines by ID', () {
      final Map<String, Object?> map = createRecipe().toFirebase();

      final Map<Object?, Object?> ingredients = Map<Object?, Object?>.from(
        map['ingredients']! as Map,
      );

      expect(
        ingredients.keys,
        containsAll(
          <String>[
            'line-chicken',
            'line-soy',
          ],
        ),
      );

      final Map<Object?, Object?> chicken = Map<Object?, Object?>.from(
        ingredients['line-chicken']! as Map,
      );

      expect(
        chicken['recipeId'],
        'recipe-adobo',
      );

      expect(
        chicken['ingredientId'],
        'ingredient-chicken',
      );

      expect(
        chicken['ingredientSku'],
        'ING-CHICKEN-001',
      );

      expect(chicken['usageUnitCode'], 'G');
      expect(chicken['quantityRequired'], 500);
      expect(chicken['costPerUsageUnit'], 0.25);
    });

    test('round-trips complete Recipe', () {
      final Recipe original = createRecipe();

      final Recipe restored = Recipe.fromFirebase(
        original.id,
        Map<Object?, Object?>.from(
          original.toFirebase(),
        ),
      );

      expect(restored.id, original.id);
      expect(
        restored.recipeCode,
        original.recipeCode,
      );
      expect(
        restored.recipeName,
        original.recipeName,
      );
      expect(
        restored.category,
        original.category,
      );
      expect(
        restored.yieldQuantity,
        original.yieldQuantity,
      );
      expect(
        restored.yieldUnitCode,
        original.yieldUnitCode,
      );
      expect(restored.active, isTrue);
      expect(restored.serverVersion, 4);
      expect(restored.ingredients, hasLength(2));

      expect(
        restored.ingredients.first.id,
        'line-chicken',
      );

      expect(
        restored.totalRecipeCost,
        original.totalRecipeCost,
      );

      expect(
        restored.costPerServing,
        original.costPerServing,
      );
    });

    test(
      'uses Firebase node key as Recipe ID',
      () {
        final Map<String, Object?> payload = createRecipe().toFirebase();

        payload['id'] = 'wrong-id';

        final Recipe restored = Recipe.fromFirebase(
          'recipe-node-id',
          Map<Object?, Object?>.from(
            payload,
          ),
        );

        expect(
          restored.id,
          'recipe-node-id',
        );

        expect(
          restored.ingredients.every(
            (RecipeIngredient line) {
              return line.recipeId == 'recipe-node-id';
            },
          ),
          isTrue,
        );
      },
    );

    test('supports empty Ingredient map', () {
      final Map<String, Object?> payload = createRecipe().toFirebase();

      payload['ingredients'] = <String, Object?>{};

      final Recipe restored = Recipe.fromFirebase(
        'recipe-adobo',
        Map<Object?, Object?>.from(
          payload,
        ),
      );

      expect(
        restored.ingredients,
        isEmpty,
      );
    });

    test('serializes deletion tombstone', () {
      final DateTime deletedAt = DateTime.utc(
        2026,
        9,
        4,
        3,
      );

      final Recipe deleted = createRecipe(
        active: false,
        deletedAt: deletedAt,
      );

      final Map<String, Object?> payload = deleted.toFirebase();

      expect(
        payload['deletedAt'],
        deletedAt.toIso8601String(),
      );

      final Recipe restored = Recipe.fromFirebase(
        deleted.id,
        Map<Object?, Object?>.from(
          payload,
        ),
      );

      expect(restored.active, isFalse);
      expect(restored.isDeleted, isTrue);
      expect(restored.deletedAt, deletedAt);
    });

    test('rejects malformed Ingredient payload', () {
      final Map<String, Object?> payload = createRecipe().toFirebase();

      payload['ingredients'] = <String, Object?>{
        'broken-line': 'not-a-map',
      };

      expect(
        () => Recipe.fromFirebase(
          'recipe-adobo',
          Map<Object?, Object?>.from(
            payload,
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate Ingredient ID', () {
      final Map<String, Object?> payload = createRecipe().toFirebase();

      payload['ingredients'] = <String, Object?>{
        'line-one': <String, Object?>{
          'id': 'same-line',
          'recipeId': 'recipe-adobo',
          'ingredientId': 'ingredient-one',
          'ingredientSku': 'ING-ONE',
          'ingredientName': 'One',
          'usageUnitCode': 'G',
          'quantityRequired': 1,
          'costPerUsageUnit': 1,
        },
        'line-two': <String, Object?>{
          'id': 'same-line',
          'recipeId': 'recipe-adobo',
          'ingredientId': 'ingredient-two',
          'ingredientSku': 'ING-TWO',
          'ingredientName': 'Two',
          'usageUnitCode': 'G',
          'quantityRequired': 1,
          'costPerUsageUnit': 1,
        },
      };

      expect(
        () => Recipe.fromFirebase(
          'recipe-adobo',
          Map<Object?, Object?>.from(
            payload,
          ),
        ),
        throwsFormatException,
      );
    });
  });
}
