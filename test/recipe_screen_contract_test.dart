import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/recipes/'
      'presentation/recipe_screen.dart',
    ).readAsStringSync();
  });

  group('Recipe Master UI contract', () {
    test('provides Recipe Master screen', () {
      expect(
        source,
        contains('class RecipeScreen'),
      );

      expect(
        source,
        contains("'Recipe Master'"),
      );
    });

    test('accepts authenticated user identity', () {
      expect(
        source,
        contains('final String currentUserId'),
      );
    });

    test('loads Recipes through Repository', () {
      expect(
        source,
        contains('RecipeRepository'),
      );

      expect(
        source,
        contains('getRecipes()'),
      );
    });

    test('opens Recipe Form for create and edit', () {
      expect(
        source,
        contains('RecipeFormScreen('),
      );

      expect(
        source,
        contains('recipe: recipe'),
      );

      expect(
        source,
        contains(
          'currentUserId: widget.currentUserId',
        ),
      );
    });

    test('provides search and filters', () {
      expect(
        source,
        contains('Search Recipes'),
      );

      expect(
        source,
        contains('RecipeStatusFilter'),
      );

      expect(
        source,
        contains('All Categories'),
      );
    });

    test('provides Recipe cost information', () {
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
        contains('Ingredient count'),
      );
    });

    test('supports Recipe editing', () {
      expect(
        source,
        contains("value: 'edit'"),
      );

      expect(
        source,
        contains('_openRecipeForm('),
      );
    });

    test('supports status changes', () {
      expect(
        source,
        contains("value: 'toggle'"),
      );

      expect(
        source,
        contains('_toggleActive('),
      );

      expect(
        source,
        contains('updateRecipe('),
      );
    });

    test('supports sync-safe deletion', () {
      expect(
        source,
        contains("value: 'delete'"),
      );

      expect(
        source,
        contains('_deleteRecipe('),
      );

      expect(
        source,
        contains('deleteRecipe('),
      );
    });

    test('shows synchronization status', () {
      expect(
        source,
        contains('MasterSyncStatus.pending'),
      );

      expect(
        source,
        contains('MasterSyncStatus.syncing'),
      );

      expect(
        source,
        contains('MasterSyncStatus.synced'),
      );

      expect(
        source,
        contains('MasterSyncStatus.error'),
      );
    });

    test('provides responsive list layout', () {
      expect(
        source,
        contains('LayoutBuilder('),
      );

      expect(
        source,
        contains('ListView.separated('),
      );

      expect(
        source,
        contains('_buildRecipeTable('),
      );
    });

    test('provides Add Recipe action', () {
      expect(
        source,
        contains("'Add Recipe'"),
      );

      expect(
        source,
        contains('FloatingActionButton.extended('),
      );
    });
  });
}
