import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/repositories/'
      'product_repository.dart',
    ).readAsStringSync();
  });

  group('Product Repository public API', () {
    test('provides Product listing', () {
      expect(
        source,
        contains(
          'Future<List<Product>> getProducts(',
        ),
      );

      expect(
        source,
        contains(
          'productDao.findAll(',
        ),
      );
    });

    test('provides Product search', () {
      expect(
        source,
        contains(
          'Future<List<Product>> searchProducts(',
        ),
      );

      expect(
        source,
        contains(
          'productDao.search(',
        ),
      );

      expect(
        source,
        contains(
          'ProductInventoryMode? inventoryMode',
        ),
      );
    });

    test('provides Product lookups', () {
      expect(
        source,
        contains(
          'Future<Product?> findProductById(',
        ),
      );

      expect(
        source,
        contains(
          'Future<Product?> findProductBySku(',
        ),
      );

      expect(
        source,
        contains(
          'Future<Product?> findProductByBarcode(',
        ),
      );
    });

    test('provides Recipe-linked Product lookup', () {
      expect(
        source,
        contains(
          'Future<List<Product>> '
          'findProductsByRecipeId(',
        ),
      );

      expect(
        source,
        contains(
          'productDao.findProductsByRecipeId(',
        ),
      );
    });

    test('provides Product save', () {
      expect(
        source,
        contains(
          'Future<Product> saveProduct(',
        ),
      );

      expect(
        source,
        contains(
          'productDao.upsert(',
        ),
      );
    });

    test('provides Product Active management', () {
      expect(
        source,
        contains(
          'Future<void> setProductActive(',
        ),
      );

      expect(
        source,
        contains(
          'productDao.setActive(',
        ),
      );
    });
  });

  group('Product save safeguards', () {
    test('validates Product before saving', () {
      expect(
        source,
        contains(
          'product.validate()',
        ),
      );

      expect(
        source,
        contains(
          'normalized.validate()',
        ),
      );
    });

    test('uses a database transaction', () {
      expect(
        source,
        contains(
          'database.transaction(',
        ),
      );

      expect(
        source,
        contains(
          '(Transaction transaction) async',
        ),
      );
    });

    test('loads existing Product', () {
      expect(
        source,
        contains(
          'productDao.findByIdIncludingInactive(',
        ),
      );
    });

    test('prevents duplicate SKU', () {
      expect(
        source,
        contains(
          'productDao.skuExists(',
        ),
      );

      expect(
        source,
        contains(
          'excludingId: product.id',
        ),
      );

      expect(
        source,
        contains(
          'A Product with SKU ',
        ),
      );
    });

    test('prevents duplicate Barcode', () {
      expect(
        source,
        contains(
          'productDao.barcodeExists(',
        ),
      );

      expect(
        source,
        contains(
          'A Product with barcode ',
        ),
      );
    });

    test('normalizes Product identity', () {
      expect(
        source,
        contains(
          'product.sku.trim().toUpperCase()',
        ),
      );

      expect(
        source,
        contains(
          'product.productName.trim()',
        ),
      );
    });

    test('preserves Product creation date', () {
      expect(
        source,
        contains(
          'existing?.createdAt ?? '
          'product.createdAt',
        ),
      );
    });

    test('refreshes Product update date', () {
      expect(
        source,
        contains(
          'DateTime.now().toUtc()',
        ),
      );
    });
  });

  group('Product Recipe safeguards', () {
    test('validates Recipe mode links', () {
      expect(
        source,
        contains(
          'ProductInventoryMode.recipe',
        ),
      );

      expect(
        source,
        contains(
          '_requireActiveRecipe(',
        ),
      );
    });

    test('loads Recipe including deleted', () {
      expect(
        source,
        contains(
          'recipeDao.findByIdIncludingDeleted(',
        ),
      );
    });

    test('rejects missing Recipe', () {
      expect(
        source,
        contains(
          'The selected Recipe was not found.',
        ),
      );
    });

    test('rejects deleted Recipe', () {
      expect(
        source,
        contains(
          'The selected Recipe has been deleted.',
        ),
      );

      expect(
        source,
        contains(
          'recipe.isDeleted',
        ),
      );
    });

    test('rejects inactive Recipe', () {
      expect(
        source,
        contains(
          'The selected Recipe is inactive.',
        ),
      );

      expect(
        source,
        contains(
          '!recipe.active',
        ),
      );
    });

    test('revalidates Recipe when activating', () {
      expect(
        source,
        contains(
          'if (active &&',
        ),
      );

      expect(
        source,
        contains(
          'existing.inventoryMode ==',
        ),
      );
    });
  });
}
