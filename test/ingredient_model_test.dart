import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

void main() {
  final DateTime createdAt = DateTime.utc(
    2026,
    9,
    1,
    6,
  );

  Ingredient createIngredient({
    String id = 'ingredient-001',
    String ingredientSku = 'ing-chicken-001',
    String ingredientName = 'Chicken Breast',
    IngredientCategory category = IngredientCategory.poultry,
    String? primarySupplierId = 'supplier-001',
    String? supplierNameSnapshot = 'Test Supplier',
    String usageUnitCode = 'GRAM',
    String? purchaseUnitCode = 'KG',
    double conversionFactor = 1000,
    double latestPurchaseCost = 220,
    double reorderLevel = 5000,
    double? parLevel = 15000,
    bool active = true,
    DateTime? deletedAt,
  }) {
    return Ingredient(
      id: id,
      ingredientSku: ingredientSku,
      ingredientName: ingredientName,
      category: category,
      primarySupplierId: primarySupplierId,
      supplierNameSnapshot: supplierNameSnapshot,
      usageUnitCode: usageUnitCode,
      purchaseUnitCode: purchaseUnitCode,
      conversionFactor: conversionFactor,
      latestPurchaseCost: latestPurchaseCost,
      reorderLevel: reorderLevel,
      parLevel: parLevel,
      active: active,
      notes: 'Boneless chicken breast',
      imagePath: null,
      createdAt: createdAt,
      updatedAt: createdAt,
      createdBy: 'user-001',
      updatedBy: 'user-001',
      syncStatus: MasterSyncStatus.pending,
      serverVersion: 0,
      deletedAt: deletedAt,
    );
  }

  group('Ingredient category', () {
    test('converts category to storage value', () {
      expect(
        ingredientCategoryToStorage(
          IngredientCategory.dryGoods,
        ),
        'DRY_GOODS',
      );
    });

    test('parses category from storage value', () {
      expect(
        ingredientCategoryFromStorage(
          'spices_and_seasonings',
        ),
        IngredientCategory.spicesAndSeasonings,
      );
    });

    test('rejects unsupported category', () {
      expect(
        () => ingredientCategoryFromStorage(
          'UNKNOWN_CATEGORY',
        ),
        throwsFormatException,
      );
    });
  });

  group('Ingredient validation', () {
    test('accepts a valid Ingredient', () {
      final Ingredient ingredient = createIngredient();

      expect(
        ingredient.validate,
        returnsNormally,
      );
    });

    test('requires Ingredient SKU', () {
      final Ingredient ingredient = createIngredient(
        ingredientSku: ' ',
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('requires Ingredient name', () {
      final Ingredient ingredient = createIngredient(
        ingredientName: '',
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('requires Usage Unit', () {
      final Ingredient ingredient = createIngredient(
        usageUnitCode: '',
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('requires a positive conversion factor', () {
      final Ingredient ingredient = createIngredient(
        conversionFactor: 0,
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('rejects a negative purchase cost', () {
      final Ingredient ingredient = createIngredient(
        latestPurchaseCost: -1,
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('rejects a negative reorder level', () {
      final Ingredient ingredient = createIngredient(
        reorderLevel: -1,
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('rejects Par Level below Reorder Level', () {
      final Ingredient ingredient = createIngredient(
        reorderLevel: 10,
        parLevel: 5,
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('requires Supplier ID and name together', () {
      final Ingredient ingredient = createIngredient(
        primarySupplierId: 'supplier-001',
        supplierNameSnapshot: null,
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });

    test('deleted Ingredient cannot remain active', () {
      final Ingredient ingredient = createIngredient(
        active: true,
        deletedAt: createdAt,
      );

      expect(
        ingredient.validate,
        throwsFormatException,
      );
    });
  });

  group('Ingredient costing', () {
    test('calculates cost per Usage Unit', () {
      final Ingredient ingredient = createIngredient(
        latestPurchaseCost: 220,
        conversionFactor: 1000,
      );

      expect(
        ingredient.costPerUsageUnit,
        closeTo(0.22, 0.000001),
      );
    });
  });

  group('Ingredient SQLite mapping', () {
    test('maps business properties to legacy columns', () {
      final Ingredient ingredient = createIngredient();

      final Map<String, Object?> map = ingredient.toSqlite();

      expect(
        map['ingredient_sku'],
        'ING-CHICKEN-001',
      );
      expect(
        map['ingredient_name'],
        'Chicken Breast',
      );
      expect(
        map['category'],
        'POULTRY',
      );
      expect(
        map['supplier_id'],
        'supplier-001',
      );
      expect(
        map['unit_of_measure'],
        'GRAM',
      );
      expect(
        map['purchase_unit'],
        'KG',
      );
      expect(
        map['conversion_factor'],
        1000,
      );
      expect(
        map['cost'],
        220,
      );
      expect(
        map['minimum_stock'],
        5000,
      );
      expect(
        map['maximum_stock'],
        15000,
      );
      expect(
        map['sync_status'],
        'PENDING',
      );
      expect(
        map['server_version'],
        0,
      );
    });

    test('round-trips through SQLite mapping', () {
      final Ingredient original = createIngredient();

      final Ingredient restored = Ingredient.fromSqlite(
        original.toSqlite(),
      );

      expect(
        restored.ingredientSku,
        'ING-CHICKEN-001',
      );
      expect(
        restored.ingredientName,
        original.ingredientName,
      );
      expect(
        restored.category,
        original.category,
      );
      expect(
        restored.usageUnitCode,
        'GRAM',
      );
      expect(
        restored.purchaseUnitCode,
        'KG',
      );
      expect(
        restored.latestPurchaseCost,
        220,
      );
    });
  });

  group('Ingredient Firebase mapping', () {
    test('uses backward-compatible Firebase field names', () {
      final Ingredient ingredient = createIngredient();

      final Map<String, Object?> map = ingredient.toFirebase();

      expect(
        map['ingredientSku'],
        'ING-CHICKEN-001',
      );
      expect(
        map['ingredientName'],
        'Chicken Breast',
      );
      expect(
        map['unitOfMeasure'],
        'GRAM',
      );
      expect(
        map['purchaseUnit'],
        'KG',
      );
      expect(
        map['minimumStock'],
        5000,
      );
      expect(
        map['maximumStock'],
        15000,
      );
      expect(
        map['active'],
        true,
      );
    });

    test('round-trips through Firebase mapping', () {
      final Ingredient original = createIngredient();

      final Map<Object?, Object?> firebaseMap = Map<Object?, Object?>.from(
        original.toFirebase(),
      );

      final Ingredient restored = Ingredient.fromFirebase(
        original.id,
        firebaseMap,
      );

      expect(
        restored.id,
        original.id,
      );
      expect(
        restored.ingredientSku,
        'ING-CHICKEN-001',
      );
      expect(
        restored.category,
        IngredientCategory.poultry,
      );
      expect(
        restored.costPerUsageUnit,
        closeTo(0.22, 0.000001),
      );
    });
  });

  group('Ingredient copyWith', () {
    test(
      'can intentionally clear optional Ingredient fields',
      () {
        final Ingredient original = createIngredient();

        final Ingredient updated = original.copyWith(
          clearPrimarySupplier: true,
          clearPurchaseUnit: true,
          clearParLevel: true,
          clearNotes: true,
          clearImagePath: true,
          clearCreatedBy: true,
          clearUpdatedBy: true,
        );

        expect(updated.primarySupplierId, isNull);
        expect(updated.supplierNameSnapshot, isNull);
        expect(updated.purchaseUnitCode, isNull);
        expect(updated.parLevel, isNull);
        expect(updated.notes, isNull);
        expect(updated.imagePath, isNull);
        expect(updated.createdBy, isNull);
        expect(updated.updatedBy, isNull);
        expect(updated.validate, returnsNormally);
      },
    );

    test('retains optional values by default', () {
      final Ingredient original = createIngredient();

      final Ingredient updated = original.copyWith(
        ingredientName: 'Updated Chicken Breast',
      );

      expect(
        updated.primarySupplierId,
        original.primarySupplierId,
      );
      expect(
        updated.supplierNameSnapshot,
        original.supplierNameSnapshot,
      );
      expect(
        updated.purchaseUnitCode,
        original.purchaseUnitCode,
      );
      expect(updated.parLevel, original.parLevel);
      expect(updated.notes, original.notes);
    });
  });
}
