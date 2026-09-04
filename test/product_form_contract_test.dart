import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/products/'
      'presentation/product_form_screen.dart',
    ).readAsStringSync();
  });

  group('Product Form contract', () {
    test('uses Product Repository', () {
      expect(
        source,
        contains('ProductRepository'),
      );

      expect(
        source,
        contains(
          '_productRepository.saveProduct(',
        ),
      );
    });

    test('loads active Recipes', () {
      expect(
        source,
        contains('RecipeRepository'),
      );

      expect(
        source,
        contains(
          '_recipeRepository.getRecipes()',
        ),
      );

      expect(
        source,
        contains(
          'recipe.active && !recipe.isDeleted',
        ),
      );
    });

    test('supports create and edit', () {
      expect(
        source,
        contains('final Product? product'),
      );

      expect(
        source,
        contains('widget.product?.id'),
      );

      expect(
        source,
        contains("'Update Product'"),
      );

      expect(
        source,
        contains("'Save Product'"),
      );
    });

    test('contains core Product fields', () {
      for (final String field in <String>[
        'SKU *',
        'Barcode',
        'Product Name *',
        'Cost *',
        'Retail Price *',
        'VAT',
      ]) {
        expect(source, contains(field));
      }
    });

    test('supports Inventory Mode', () {
      expect(
        source,
        contains(
          'ProductInventoryMode',
        ),
      );

      expect(
        source,
        contains(
          "labelText: 'Inventory Mode *'",
        ),
      );

      expect(
        source,
        contains(
          '_changeInventoryMode',
        ),
      );
    });

    test('supports Costing Method', () {
      expect(
        source,
        contains(
          'ProductCostingMethod',
        ),
      );

      expect(
        source,
        contains(
          "labelText: 'Costing Method *'",
        ),
      );
    });

    test('shows Recipe only for Recipe mode', () {
      expect(
        source,
        contains(
          '_inventoryMode == '
          'ProductInventoryMode.recipe',
        ),
      );

      expect(
        source,
        contains(
          "labelText: 'Recipe *'",
        ),
      );
    });

    test('clears Recipe outside Recipe mode', () {
      expect(
        source,
        contains(
          'if (mode != '
          'ProductInventoryMode.recipe)',
        ),
      );

      expect(
        source,
        contains(
          '_recipeId = null',
        ),
      );
    });

    test('corrects Ingredient costing', () {
      expect(
        source,
        contains(
          'ProductCostingMethod.ingredient',
        ),
      );

      expect(
        source,
        contains(
          '_costingMethod = '
          'ProductCostingMethod.manual',
        ),
      );
    });

    test('requires Recipe selection', () {
      expect(
        source,
        contains(
          'Select an active Recipe',
        ),
      );

      expect(
        source,
        contains(
          "'Recipe is required.'",
        ),
      );
    });

    test('uses responsive layouts', () {
      expect(
        source,
        contains('LayoutBuilder'),
      );

      expect(
        source,
        contains(
          'constraints.maxWidth >= 680',
        ),
      );

      expect(
        source,
        contains(
          'constraints.maxWidth < 480',
        ),
      );
    });

    test('handles reference errors', () {
      expect(
        source,
        contains(
          'Unable to load active Recipes.',
        ),
      );

      expect(source, contains("'Retry'"));
    });

    test('displays save errors', () {
      expect(
        source,
        contains(
          'Unable to save Product:',
        ),
      );

      expect(
        source,
        contains('SnackBar'),
      );
    });
  });
}
