import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String hubSource;
  late String recipeScreenSource;

  setUpAll(() {
    hubSource = File(
      'lib/features/master_data/presentation/'
      'master_data_hub.dart',
    ).readAsStringSync();

    recipeScreenSource = File(
      'lib/features/master_data/recipes/'
      'presentation/recipe_screen.dart',
    ).readAsStringSync();
  });

  group('Master Data Hub Recipe integration', () {
    test('imports Recipe Screen', () {
      expect(
        hubSource,
        contains(
          "import 'package:kitchen_sync/features/"
          "master_data/recipes/presentation/"
          "recipe_screen.dart';",
        ),
      );
    });

    test('displays Recipe Master card', () {
      expect(
        hubSource,
        contains(
          "title: 'Recipe Master'",
        ),
      );

      expect(
        hubSource,
        contains(
          'Manage Recipes, Ingredients, yields, ',
        ),
      );

      expect(
        hubSource,
        contains(
          'and cost per serving.',
        ),
      );
    });

    test('enables Recipe Master card', () {
      final int cardPosition = hubSource.indexOf(
        "title: 'Recipe Master'",
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

    test('opens Recipe Screen', () {
      expect(
        hubSource,
        contains('RecipeScreen('),
      );

      expect(
        hubSource,
        contains(
          'MaterialPageRoute<void>(',
        ),
      );
    });

    test('passes authenticated user ID', () {
      final int screenPosition = hubSource.indexOf(
        'RecipeScreen(',
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

    test('Recipe Screen requires user ID', () {
      expect(
        recipeScreenSource,
        contains(
          'final String currentUserId',
        ),
      );

      expect(
        recipeScreenSource,
        contains(
          'required this.currentUserId',
        ),
      );
    });

    test('places Recipe before Sync card', () {
      final int recipePosition = hubSource.indexOf(
        "title: 'Recipe Master'",
      );

      final int syncPosition = hubSource.indexOf(
        "'Sync Master Data'",
      );

      expect(
        recipePosition,
        greaterThanOrEqualTo(0),
      );

      expect(
        syncPosition,
        greaterThan(recipePosition),
      );
    });

    test('keeps existing Master Data cards', () {
      expect(
        hubSource,
        contains(
          "title: 'Units of Measure'",
        ),
      );

      expect(
        hubSource,
        contains(
          "title: 'Suppliers'",
        ),
      );

      expect(
        hubSource,
        contains(
          "title: 'Ingredients'",
        ),
      );

      expect(
        hubSource,
        contains(
          "'Sync Master Data'",
        ),
      );
    });

    test('uses Recipe menu icon', () {
      final int cardPosition = hubSource.indexOf(
        "title: 'Recipe Master'",
      );

      final int iconPosition = hubSource.indexOf(
        'Icons.menu_book_outlined',
        cardPosition,
      );

      expect(
        iconPosition,
        greaterThan(cardPosition),
      );
    });
  });
}
