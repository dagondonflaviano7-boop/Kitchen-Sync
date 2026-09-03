import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/recipes/'
      'presentation/recipe_form_screen.dart',
    ).readAsStringSync();
  });

  group('Recipe Form public contract', () {
    test('provides RecipeFormScreen', () {
      expect(
        source,
        contains('class RecipeFormScreen'),
      );

      expect(
        source,
        contains('extends StatefulWidget'),
      );
    });

    test('accepts Recipe and current user', () {
      expect(
        source,
        contains('final Recipe? recipe'),
      );

      expect(
        source,
        contains('final String currentUserId'),
      );
    });

    test('uses Recipe Repository', () {
      expect(
        source,
        contains('RecipeRepository'),
      );

      expect(
        source,
        contains('createRecipe('),
      );

      expect(
        source,
        contains('updateRecipe('),
      );
    });

    test('loads active Ingredients', () {
      expect(
        source,
        contains('IngredientRepository'),
      );

      expect(
        RegExp(
          r'getIngredients\s*\(\s*'
          r'includeInactive:\s*false,\s*\)',
        ).hasMatch(source),
        isTrue,
      );
    });

    test('loads active Units', () {
      expect(
        source,
        contains('UnitOfMeasureRepository'),
      );

      expect(
        RegExp(
          r'getUnits\s*\(\s*'
          r'includeInactive:\s*false,\s*\)',
        ).hasMatch(source),
        isTrue,
      );
    });

    test('provides Recipe header inputs', () {
      expect(
        source,
        contains('Recipe Code *'),
      );

      expect(
        source,
        contains('Recipe Name *'),
      );

      expect(
        source,
        contains('Category *'),
      );

      expect(
        source,
        contains('Yield Quantity *'),
      );

      expect(
        source,
        contains('Yield Unit *'),
      );
    });

    test('provides Ingredient line editing', () {
      expect(
        source,
        contains('Add Ingredient'),
      );

      expect(
        source,
        contains('Quantity Required'),
      );

      expect(
        source,
        contains('Cost per Usage Unit'),
      );

      expect(
        source,
        contains('Remove Ingredient'),
      );
    });

    test('shows live costing', () {
      expect(
        source,
        contains('Total Recipe Cost'),
      );

      expect(
        source,
        contains('Cost per Serving'),
      );

      expect(
        source,
        contains('extendedCost'),
      );
    });

    test('protects unsaved changes', () {
      expect(
        source,
        contains('_confirmDiscard'),
      );

      expect(
        source,
        contains('Discard changes?'),
      );
    });

    test('returns save result to caller', () {
      expect(
        source,
        contains('Navigator.of(context).pop(true)'),
      );
    });
  });
}
