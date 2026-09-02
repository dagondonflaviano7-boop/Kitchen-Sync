import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';

void main() {
  group('RecipeCategory', () {
    test('contains expected values', () {
      expect(
        RecipeCategory.values.length,
        6,
      );
    });
  });

  group('RecipeIngredient', () {
    test('calculates line cost', () {
      final RecipeIngredient item = RecipeIngredient(
        id: '1',
        recipeId: 'R1',
        ingredientId: 'I1',
        ingredientSku: 'ING001',
        ingredientName: 'Chicken',
        usageUnitCode: 'G',
        quantityRequired: 500,
        costPerUsageUnit: 0.25,
      );

      expect(
        item.extendedCost,
        125,
      );
    });
  });

  group('Recipe', () {
    test('calculates total recipe cost', () {
      final Recipe recipe = Recipe(
        id: 'R1',
        recipeCode: 'REC001',
        recipeName: 'Chicken Adobo',
        category: RecipeCategory.mainDish,
        yieldQuantity: 10,
        yieldUnitCode: 'SERVING',
        active: true,
        ingredients: [
          RecipeIngredient(
            id: '1',
            recipeId: 'R1',
            ingredientId: 'I1',
            ingredientSku: 'ING001',
            ingredientName: 'Chicken',
            usageUnitCode: 'G',
            quantityRequired: 500,
            costPerUsageUnit: 0.25,
          ),
          RecipeIngredient(
            id: '2',
            recipeId: 'R1',
            ingredientId: 'I2',
            ingredientSku: 'ING002',
            ingredientName: 'Soy Sauce',
            usageUnitCode: 'ML',
            quantityRequired: 250,
            costPerUsageUnit: 0.08,
          ),
        ],
      );

      expect(
        recipe.totalRecipeCost,
        145,
      );
    });

    test('calculates cost per serving', () {
      final Recipe recipe = Recipe(
        id: 'R1',
        recipeCode: 'REC001',
        recipeName: 'Chicken Adobo',
        category: RecipeCategory.mainDish,
        yieldQuantity: 10,
        yieldUnitCode: 'SERVING',
        active: true,
        ingredients: [
          RecipeIngredient(
            id: '1',
            recipeId: 'R1',
            ingredientId: 'I1',
            ingredientSku: 'ING001',
            ingredientName: 'Chicken',
            usageUnitCode: 'G',
            quantityRequired: 500,
            costPerUsageUnit: 0.25,
          ),
        ],
      );

      expect(
        recipe.costPerServing,
        12.5,
      );
    });

    test('protects against zero yield', () {
      final Recipe recipe = Recipe(
        id: 'R1',
        recipeCode: 'REC001',
        recipeName: 'Chicken Adobo',
        category: RecipeCategory.mainDish,
        yieldQuantity: 0,
        yieldUnitCode: 'SERVING',
        active: true,
        ingredients: const [],
      );

      expect(
        recipe.costPerServing,
        0,
      );
    });
  });
}
