import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/services/'
      'default_master_data_seed_service.dart',
    ).readAsStringSync();
  });

  group('Default Master Data seed', () {
    test('provides 100 processed records', () {
      expect(
        source,
        contains('processedTotal == 100'),
      );
    });

    test('defines ten Units', () {
      expect(
        RegExp(r"_unit\('").allMatches(source).length,
        greaterThanOrEqualTo(10),
      );
    });

    test('defines ten Suppliers', () {
      expect(
        source,
        contains("'Clean Kitchen Supplies'"),
      );
    });

    test('defines forty Ingredients', () {
      expect(
        source,
        contains("'Drinking Water'"),
      );
    });

    test('defines fifteen Recipes', () {
      expect(
        source,
        contains("'House Sauce'"),
      );
    });

    test('defines twenty-five Products', () {
      expect(
        source,
        contains("'Bread Roll'"),
      );
    });

    test('uses deterministic seed identities', () {
      expect(
        source,
        contains("'seed-unit-"),
      );

      expect(
        source,
        contains("'seed-supplier-"),
      );

      expect(
        source,
        contains("'seed-ingredient-"),
      );

      expect(
        source,
        contains("'seed-recipe-"),
      );

      expect(
        source,
        contains("'seed-product-"),
      );
    });

    test('checks existing records before saves', () {
      expect(
        source,
        contains('existingUnits.any('),
      );

      expect(
        source,
        contains('existingIngredients.any('),
      );

      expect(
        source,
        contains('recipeCodeExists'),
      );

      expect(
        source,
        contains('findProductBySku'),
      );
    });

    test('uses repositories for local-first writes', () {
      expect(
        source,
        contains('unitRepository.saveUnit'),
      );

      expect(
        source,
        contains('supplierRepository.saveSupplier'),
      );

      expect(
        source,
        contains('ingredientRepository.saveIngredient'),
      );

      expect(
        source,
        contains('recipeRepository.createRecipe'),
      );

      expect(
        source,
        contains('productRepository.saveProduct'),
      );
    });

    test('creates dependencies in the correct order', () {
      final int units = source.indexOf(
        'for (final UnitOfMeasure unit',
      );

      final int suppliers = source.indexOf(
        'for (final Supplier supplier',
      );

      final int ingredients = source.indexOf(
        'for (final Ingredient ingredient',
      );

      final int recipes = source.indexOf(
        'for (final Recipe recipe',
      );

      final int products = source.indexOf(
        'for (final Product product',
      );

      expect(units, greaterThanOrEqualTo(0));
      expect(suppliers, greaterThan(units));
      expect(ingredients, greaterThan(suppliers));
      expect(recipes, greaterThan(ingredients));
      expect(products, greaterThan(recipes));
    });

    test('syncs only after local creation', () {
      final int productSave = source.indexOf(
        'productRepository.saveProduct',
      );

      final int sync = source.indexOf(
        'MasterDataAutoSync.instance.trigger',
      );

      expect(productSave, greaterThanOrEqualTo(0));
      expect(sync, greaterThan(productSave));
    });

    test('uses one forced synchronization', () {
      expect(
        source,
        contains(
          'reason: MasterDataAutoSyncReason.manual',
        ),
      );

      expect(
        source,
        contains('force: true'),
      );
    });

    test('does not delete existing data', () {
      expect(
        source,
        isNot(
          contains('.delete'),
        ),
      );

      expect(
        source,
        isNot(
          contains('softDelete'),
        ),
      );
    });
  });
}
