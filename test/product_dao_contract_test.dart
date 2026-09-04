import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/local/daos/product_dao.dart',
    ).readAsStringSync();
  });

  group('Product DAO contract', () {
    test('uses Products table', () {
      expect(
        source,
        contains("'products'"),
      );
    });

    test('supports Product upsert', () {
      expect(
        source,
        contains('Future<void> upsert('),
      );

      expect(
        source,
        contains('product.validate()'),
      );

      expect(
        source,
        contains('product.toSqlite()'),
      );

      expect(
        source,
        contains(
          'ConflictAlgorithm.replace',
        ),
      );
    });

    test('supports ID lookups', () {
      expect(
        source,
        contains('Future<Product?> findById('),
      );

      expect(
        source,
        contains(
          'Future<Product?> '
          'findByIdIncludingInactive(',
        ),
      );
    });

    test('supports SKU lookup', () {
      expect(
        source,
        contains('Future<Product?> findBySku('),
      );

      expect(
        source,
        contains(
          'productSku.trim().toUpperCase()',
        ),
      );
    });

    test('supports Barcode lookup', () {
      expect(
        source,
        contains(
          'Future<Product?> findByBarcode(',
        ),
      );

      expect(
        source,
        contains(
          "'Barcode is required.'",
        ),
      );
    });

    test('supports Product listing', () {
      expect(
        source,
        contains('Future<List<Product>> findAll('),
      );

      expect(
        source,
        contains(
          'product_name COLLATE NOCASE',
        ),
      );

      expect(source, contains('sku'));
    });

    test('supports Product searching', () {
      expect(
        source,
        contains('Future<List<Product>> search('),
      );

      for (final String field in <String>[
        'sku LIKE ?',
        'barcode LIKE ?',
        'product_name LIKE ?',
        'department_name LIKE ?',
        'class_name LIKE ?',
        'subclass_name LIKE ?',
        'supplier_name LIKE ?',
        'brand_name LIKE ?',
      ]) {
        expect(source, contains(field));
      }
    });

    test('supports Inventory Mode filtering', () {
      expect(
        source,
        contains(
          "conditions.add('inventory_mode = ?')",
        ),
      );

      expect(
        source,
        contains(
          'productInventoryModeToStorage(',
        ),
      );
    });

    test('supports duplicate SKU checks', () {
      expect(
        source,
        contains('Future<bool> skuExists('),
      );

      expect(
        source,
        contains('String? excludingId'),
      );
    });

    test('supports duplicate Barcode checks', () {
      expect(
        source,
        contains('Future<bool> barcodeExists('),
      );
    });

    test('supports Active status updates', () {
      expect(
        source,
        contains('Future<void> setActive('),
      );

      expect(
        source,
        contains("'active': active ? 1 : 0"),
      );

      expect(
        source,
        contains(
          'The Product record was not found.',
        ),
      );
    });

    test('supports Recipe-linked Products', () {
      expect(
        source,
        contains(
          'Future<List<Product>> '
          'findProductsByRecipeId(',
        ),
      );

      expect(
        source,
        contains("'recipe_id = ?'"),
      );
    });

    test('maps rows using Product model', () {
      expect(
        source,
        contains('Product.fromSqlite'),
      );
    });
  });
}
