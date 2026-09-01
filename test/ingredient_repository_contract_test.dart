import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/repositories/'
      'ingredient_repository.dart',
    ).readAsStringSync();
  });

  group('Ingredient Repository public API', () {
    test('provides Ingredient listing', () {
      expect(
        source,
        contains(
          'Future<List<Ingredient>> getIngredients(',
        ),
      );
      expect(
        source,
        contains('ingredientDao.findAll('),
      );
    });

    test('provides Ingredient search and filters', () {
      expect(
        source,
        contains(
          'Future<List<Ingredient>> searchIngredients(',
        ),
      );
      expect(
        source,
        contains('ingredientDao.search('),
      );
      expect(
        source,
        contains('IngredientCategory? category'),
      );
      expect(
        source,
        contains('String? supplierId'),
      );
    });

    test('provides ID and SKU lookup', () {
      expect(
        source,
        contains(
          'Future<Ingredient?> findIngredientById(',
        ),
      );
      expect(
        source,
        contains(
          'Future<Ingredient?> findIngredientBySku(',
        ),
      );
      expect(
        source,
        contains('ingredientDao.findById('),
      );
      expect(
        source,
        contains('ingredientDao.findBySku('),
      );
    });

    test('provides save, status, and delete operations', () {
      expect(
        source,
        contains(
          'Future<Ingredient> saveIngredient(',
        ),
      );
      expect(
        source,
        contains(
          'Future<void> setIngredientActive(',
        ),
      );
      expect(
        source,
        contains(
          'Future<void> deleteIngredient(',
        ),
      );
    });
  });

  group('Ingredient save safeguards', () {
    test('validates the Ingredient model', () {
      expect(
        source,
        contains('ingredient.validate()'),
      );
      expect(
        RegExp(
          r'normalized\.validate\(\)',
        ).hasMatch(source),
        isTrue,
      );
    });

    test('requires authenticated user identity', () {
      expect(
        source,
        contains(
          '_requireAuthenticatedUserId(',
        ),
      );
      expect(
        source,
        contains(
          'Authenticated user identity is required.',
        ),
      );
    });

    test('checks for a previously deleted record', () {
      expect(
        source,
        contains(
          'ingredientDao.findByIdIncludingDeleted(',
        ),
      );
      expect(
        source,
        contains(
          'A deleted Ingredient cannot be edited.',
        ),
      );
    });

    test('checks duplicate Ingredient SKU', () {
      expect(
        source,
        contains('ingredientDao.skuExists('),
      );
      expect(
        source,
        contains(
          'excludingId: ingredient.id',
        ),
      );
      expect(
        source,
        contains(
          'An Ingredient with SKU ',
        ),
      );
      expect(
        source,
        contains('already exists.'),
      );
    });

    test('validates Usage Unit', () {
      expect(
        source,
        contains(
          "fieldName: 'Usage Unit'",
        ),
      );
    });

    test('validates optional Purchase Unit', () {
      expect(
        source,
        contains(
          "fieldName: 'Purchase Unit'",
        ),
      );
      expect(
        source,
        contains(
          'clearPurchaseUnit: purchaseUnit == null',
        ),
      );
    });

    test('validates the selected Supplier', () {
      expect(
        source,
        contains(
          '_requireActiveSupplier(',
        ),
      );
      expect(
        source,
        contains(
          'clearPrimarySupplier: supplier == null',
        ),
      );
    });

    test('uses official Supplier name snapshot', () {
      expect(
        source,
        contains(
          'supplierNameSnapshot:',
        ),
      );
      expect(
        source,
        contains(
          'supplier?.supplierName',
        ),
      );
    });

    test('normalizes Ingredient identity and Units', () {
      expect(
        source,
        contains(
          'ingredient.ingredientSku.trim().toUpperCase()',
        ),
      );
      expect(
        source,
        contains(
          'ingredient.ingredientName.trim()',
        ),
      );
      expect(
        source,
        contains(
          'usageUnit.code.trim().toUpperCase()',
        ),
      );
    });

    test('preserves creation audit during editing', () {
      expect(
        source,
        contains(
          'existing?.createdAt ??',
        ),
      );
      expect(
        source,
        contains(
          'existing?.createdBy ??',
        ),
      );
    });

    test('records authenticated update audit', () {
      expect(
        source,
        contains(
          'updatedBy: authenticatedUserId',
        ),
      );
    });

    test('preserves current server version', () {
      expect(
        source,
        contains(
          'existing?.serverVersion ??',
        ),
      );
    });

    test('marks a local save Pending', () {
      expect(
        source,
        contains(
          'syncStatus: MasterSyncStatus.pending',
        ),
      );
    });

    test('uses a transaction for save', () {
      expect(
        source,
        contains('database.transaction('),
      );
      expect(
        source,
        contains('ingredientDao.upsert('),
      );
    });
  });

  group('Unit validation', () {
    test('normalizes Unit codes', () {
      expect(
        source,
        contains(
          'unitCode.trim().toUpperCase()',
        ),
      );
    });

    test('loads Unit through Unit DAO', () {
      expect(
        source,
        contains('unitDao.findByCode('),
      );
    });

    test('requires Unit existence', () {
      expect(
        source,
        contains('does not exist.'),
      );
    });

    test('requires active non-deleted Unit', () {
      expect(
        source,
        contains(
          '!unit.active || unit.deletedAt != null',
        ),
      );
      expect(
        source,
        contains(
          'Select an active Unit.',
        ),
      );
    });
  });

  group('Supplier validation', () {
    test('loads Supplier through Supplier DAO', () {
      expect(
        source,
        contains('supplierDao.findById('),
      );
    });

    test('requires Supplier existence', () {
      expect(
        source,
        contains(
          'The selected Supplier does not exist.',
        ),
      );
    });

    test('requires active non-deleted Supplier', () {
      expect(
        source,
        contains(
          '!supplier.active || supplier.deletedAt != null',
        ),
      );
      expect(
        source,
        contains(
          'Select an active Supplier.',
        ),
      );
    });
  });

  group('Ingredient status safeguards', () {
    test('requires authenticated user for status change', () {
      expect(
        source,
        contains(
          'setIngredientActive(',
        ),
      );
      expect(
        source,
        contains(
          'updatedBy: authenticatedUserId',
        ),
      );
    });

    test('uses Ingredient DAO status operation', () {
      expect(
        source,
        contains(
          'ingredientDao.setActive(',
        ),
      );
    });
  });

  group('Ingredient deletion safeguards', () {
    test('uses a deletion transaction', () {
      expect(
        source,
        contains(
          'Future<void> deleteIngredient(',
        ),
      );
      expect(
        source,
        contains('database.transaction('),
      );
    });

    test('requires an existing non-deleted Ingredient', () {
      expect(
        source,
        contains(
          'The Ingredient record was not found.',
        ),
      );
    });

    test('checks Ingredient references', () {
      expect(
        source,
        contains(
          'ingredientDao.isReferenced(',
        ),
      );
    });

    test('blocks deletion when Ingredient is referenced', () {
      expect(
        source,
        contains(
          'This Ingredient cannot be deleted because ',
        ),
      );
      expect(
        source,
        contains(
          'Deactivate it instead.',
        ),
      );
    });

    test('uses DAO soft deletion', () {
      expect(
        source,
        contains(
          'ingredientDao.softDelete(',
        ),
      );
      expect(
        source,
        contains(
          'updatedBy: authenticatedUserId',
        ),
      );
    });

    test('does not physically delete Ingredient rows', () {
      expect(
        source,
        isNot(
          contains(
            "database.delete(\n"
            "      'ingredients'",
          ),
        ),
      );
    });
  });

  group('Ingredient inventory isolation', () {
    test('does not update Ingredient Inventory', () {
      expect(
        source,
        isNot(
          contains(
            "database.update(\n"
            "      'ingredient_inventory'",
          ),
        ),
      );
    });

    test('does not insert Ingredient movements', () {
      expect(
        source,
        isNot(
          contains(
            "database.insert(\n"
            "      'ingredient_movements'",
          ),
        ),
      );
    });

    test('does not delete stock history', () {
      expect(
        source,
        isNot(
          contains(
            "database.delete(\n"
            "      'ingredient_inventory'",
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            "database.delete(\n"
            "      'ingredient_movements'",
          ),
        ),
      );
    });
  });
}
