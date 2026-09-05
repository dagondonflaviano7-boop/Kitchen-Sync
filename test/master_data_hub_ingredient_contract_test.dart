import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String hubSource;
  late String ingredientScreenSource;

  setUpAll(() {
    hubSource = File(
      'lib/features/master_data/presentation/'
      'master_data_hub.dart',
    ).readAsStringSync();

    ingredientScreenSource = File(
      'lib/features/master_data/ingredients/'
      'presentation/ingredient_screen.dart',
    ).readAsStringSync();
  });

  group('Master Data Hub Ingredient integration', () {
    test('imports Ingredient Screen', () {
      expect(
        hubSource,
        contains(
          "import 'package:kitchen_sync/features/"
          "master_data/ingredients/presentation/"
          "ingredient_screen.dart';",
        ),
      );
    });

    test('displays the Ingredients card', () {
      expect(
        hubSource,
        contains("title: 'Ingredients'"),
      );

      expect(
        hubSource,
        contains(
          'Manage Ingredient units, costs, ',
        ),
      );

      expect(
        hubSource,
        contains(
          'Suppliers, and stock-control levels.',
        ),
      );
    });

    test('enables the Ingredients card', () {
      final int cardPosition = hubSource.indexOf(
        "title: 'Ingredients'",
      );

      final int enabledPosition = hubSource.indexOf(
        'enabled: true',
        cardPosition,
      );

      final int nextCardPosition = hubSource.indexOf(
        '_MasterDataCard(',
        cardPosition + 1,
      );

      expect(
        cardPosition,
        greaterThanOrEqualTo(0),
      );

      expect(
        enabledPosition,
        greaterThan(cardPosition),
      );

      expect(
        nextCardPosition == -1 || enabledPosition < nextCardPosition,
        isTrue,
      );
    });

    test('opens Ingredient Screen', () {
      expect(
        hubSource,
        contains('IngredientScreen('),
      );

      expect(
        hubSource,
        contains('MaterialPageRoute<void>('),
      );
    });

    test('passes authenticated user ID', () {
      final int screenPosition = hubSource.indexOf(
        'IngredientScreen(',
      );

      final int userPosition = hubSource.indexOf(
        'widget.currentUserId',
        screenPosition,
      );

      expect(
        screenPosition,
        greaterThanOrEqualTo(0),
      );

      expect(
        userPosition,
        greaterThan(screenPosition),
      );
    });

    test('Ingredient Screen accepts current user ID', () {
      expect(
        ingredientScreenSource,
        contains(
          'final String? currentUserId',
        ),
      );

      expect(
        ingredientScreenSource,
        contains('this.currentUserId'),
      );
    });

    test('keeps Units of Measure card', () {
      expect(
        hubSource,
        contains(
          "title: 'Units of Measure'",
        ),
      );

      expect(
        hubSource,
        contains('UnitOfMeasureScreen()'),
      );
    });

    test('keeps Suppliers card', () {
      expect(
        hubSource,
        contains("title: 'Suppliers'"),
      );

      expect(
        hubSource,
        contains('SupplierScreen('),
      );
    });

    test('keeps Master Data Sync card', () {
      expect(
        hubSource,
        contains("'Sync Master Data'"),
      );

      expect(
        hubSource,
        contains('_synchronizeMasterData'),
      );
    });

    test('Sync card includes Ingredients', () {
      expect(
        hubSource,
        contains(
          "'Suppliers, Ingredients, Recipes, '",
        ),
      );

      expect(
        hubSource,
        contains("'and Products with Firebase.'"),
      );
    });

    test('Hub remains responsive', () {
      expect(
        hubSource,
        contains(
          'constraints.maxWidth >= 700',
        ),
      );

      expect(
        hubSource,
        contains(
          'crossAxisCount: wide ? 2 : 1',
        ),
      );
    });
  });
}
