import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/products/'
      'presentation/product_screen.dart',
    ).readAsStringSync();
  });

  group('Product Master Screen contract', () {
    test('uses Product Repository', () {
      expect(source, contains('ProductRepository'));

      expect(
        source,
        contains('_repository.getProducts('),
      );
    });

    test('loads Recipe references', () {
      expect(source, contains('RecipeRepository'));

      expect(
        source,
        contains('_recipeRepository.getRecipes()'),
      );

      expect(
        source,
        contains('_recipesById'),
      );
    });

    test('opens Product Form', () {
      expect(
        source,
        contains('ProductFormScreen('),
      );

      expect(
        source,
        contains('_openProductForm('),
      );
    });

    test('supports Product searching', () {
      expect(
        source,
        contains("'Search Products'"),
      );

      expect(source, contains('product.sku'));

      expect(
        source,
        contains('product.barcode'),
      );

      expect(
        source,
        contains('product.productName'),
      );
    });

    test('supports Product status filters', () {
      expect(
        source,
        contains('ProductStatusFilter'),
      );

      expect(source, contains("'Active'"));
      expect(source, contains("'Inactive'"));
    });

    test('supports Inventory Mode filters', () {
      expect(
        source,
        contains(
          'ProductInventoryMode?',
        ),
      );

      expect(
        source,
        contains("'All Inventory Modes'"),
      );
    });

    test('supports activating Products', () {
      expect(
        source,
        contains(
          '_repository.setProductActive(',
        ),
      );

      expect(
        source,
        contains("'Activate Product?'"),
      );

      expect(
        source,
        contains("'Deactivate Product?'"),
      );
    });

    test('displays linked Recipe', () {
      expect(
        source,
        contains("'Recipe: "),
      );

      expect(
        source,
        contains('_recipeName(product)'),
      );

      expect(
        source,
        contains('product.usesRecipeInventory'),
      );
    });

    test('displays Product financials', () {
      expect(source, contains("'Cost: '"));
      expect(source, contains("'Retail: '"));
      expect(source, contains("'Profit: '"));
      expect(source, contains("'Margin: '"));

      expect(
        source,
        contains('product.grossProfit'),
      );

      expect(
        source,
        contains('product.grossMargin'),
      );
    });

    test('supports Product actions', () {
      expect(
        source,
        contains('PopupMenuButton<String>'),
      );

      expect(source, contains("'Edit'"));
      expect(source, contains("'Deactivate'"));
      expect(source, contains("'Activate'"));
    });

    test('supports loading and error states', () {
      expect(
        source,
        contains('CircularProgressIndicator'),
      );

      expect(
        source,
        contains('Unable to load Products.'),
      );

      expect(source, contains("'Retry'"));
    });

    test('supports empty states', () {
      expect(
        source,
        contains(
          'No Products match the ',
        ),
      );

      expect(
        source,
        contains(
          'No Products have been ',
        ),
      );
    });

    test('provides Add Product action', () {
      expect(
        source,
        contains("'Add Product'"),
      );

      expect(
        source,
        contains(
          'FloatingActionButton.extended',
        ),
      );
    });
  });
}
