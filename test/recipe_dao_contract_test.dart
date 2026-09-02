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
}
