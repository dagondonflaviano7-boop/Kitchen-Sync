import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

void main() {
  Product createProduct({
    ProductInventoryMode inventoryMode = ProductInventoryMode.direct,
    ProductCostingMethod costingMethod = ProductCostingMethod.manual,
    String? recipeId,
    double cost = 50,
    double retailPrice = 100,
    double vat = 12,
  }) {
    return Product(
      id: 'product-001',
      sku: 'sku-001',
      barcode: '1234567890',
      productName: 'Chicken Meal',
      department: 'Food',
      supplierId: 'supplier-001',
      supplierName: 'Test Supplier',
      cost: cost,
      retailPrice: retailPrice,
      vat: vat,
      inventoryMode: inventoryMode,
      costingMethod: costingMethod,
      recipeId: recipeId,
      createdAt: DateTime.utc(
        2026,
        9,
        4,
        1,
      ),
      updatedAt: DateTime.utc(
        2026,
        9,
        4,
        2,
      ),
    );
  }

  group('Product domain model', () {
    test('accepts Direct inventory Product', () {
      final Product product = createProduct();

      expect(
        () => product.validate(),
        returnsNormally,
      );

      expect(product.usesDirectInventory, isTrue);
      expect(product.hasRecipe, isFalse);
    });

    test('accepts Recipe inventory Product', () {
      final Product product = createProduct(
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.ingredient,
        recipeId: 'recipe-001',
      );

      expect(
        () => product.validate(),
        returnsNormally,
      );

      expect(product.usesRecipeInventory, isTrue);
      expect(product.hasRecipe, isTrue);
    });

    test('requires Recipe ID for Recipe mode', () {
      final Product product = createProduct(
        inventoryMode: ProductInventoryMode.recipe,
      );

      expect(
        product.validate,
        throwsFormatException,
      );
    });

    test('rejects Recipe ID for Direct mode', () {
      final Product product = createProduct(
        recipeId: 'recipe-001',
      );

      expect(
        product.validate,
        throwsFormatException,
      );
    });

    test('rejects Recipe ID for None mode', () {
      final Product product = createProduct(
        inventoryMode: ProductInventoryMode.none,
        recipeId: 'recipe-001',
      );

      expect(
        product.validate,
        throwsFormatException,
      );
    });

    test(
      'rejects Ingredient costing for Direct mode',
      () {
        final Product product = createProduct(
          costingMethod: ProductCostingMethod.ingredient,
        );

        expect(
          product.validate,
          throwsFormatException,
        );
      },
    );

    test('rejects negative financial values', () {
      expect(
        () => createProduct(
          cost: -1,
        ).validate(),
        throwsFormatException,
      );

      expect(
        () => createProduct(
          retailPrice: -1,
        ).validate(),
        throwsFormatException,
      );

      expect(
        () => createProduct(
          vat: -1,
        ).validate(),
        throwsFormatException,
      );
    });

    test('serializes Product to SQLite', () {
      final Product product = createProduct(
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.ingredient,
        recipeId: 'recipe-001',
      );

      final Map<String, Object?> map = product.toSqlite();

      expect(map['sku'], 'SKU-001');
      expect(map['inventory_mode'], 'RECIPE');
      expect(
        map['costing_method'],
        'INGREDIENT',
      );
      expect(map['recipe_id'], 'recipe-001');
      expect(map['active'], 1);
    });

    test('round-trips SQLite Product', () {
      final Product original = createProduct(
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.hybrid,
        recipeId: 'recipe-001',
      );

      final Product restored = Product.fromSqlite(
        original.toSqlite(),
      );

      expect(restored.id, original.id);
      expect(restored.sku, 'SKU-001');
      expect(
        restored.inventoryMode,
        ProductInventoryMode.recipe,
      );
      expect(
        restored.costingMethod,
        ProductCostingMethod.hybrid,
      );
      expect(restored.recipeId, 'recipe-001');
    });

    test('round-trips Firebase Product', () {
      final Product original = createProduct(
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.ingredient,
        recipeId: 'recipe-001',
      );

      final Product restored = Product.fromFirebase(
        original.id,
        Map<Object?, Object?>.from(
          original.toFirebase(),
        ),
      );

      expect(restored.id, original.id);
      expect(restored.recipeId, 'recipe-001');
      expect(
        restored.inventoryMode,
        ProductInventoryMode.recipe,
      );
    });

    test('Firebase node key overrides payload ID', () {
      final Map<String, Object?> payload = createProduct().toFirebase();

      payload['id'] = 'wrong-id';

      final Product restored = Product.fromFirebase(
        'firebase-product-id',
        Map<Object?, Object?>.from(
          payload,
        ),
      );

      expect(
        restored.id,
        'firebase-product-id',
      );
    });

    test('copyWith can clear Recipe ID', () {
      final Product recipeProduct = createProduct(
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.ingredient,
        recipeId: 'recipe-001',
      );

      final Product directProduct = recipeProduct.copyWith(
        inventoryMode: ProductInventoryMode.direct,
        costingMethod: ProductCostingMethod.manual,
        recipeId: null,
      );

      expect(directProduct.recipeId, isNull);

      expect(
        () => directProduct.validate(),
        returnsNormally,
      );
    });

    test('calculates Product margin values', () {
      final Product product = createProduct();

      expect(product.grossProfit, 50);
      expect(product.grossMargin, 50);
      expect(product.priceIncludingVat, 112);
    });
  });
  productSyncMetadataTests();
}

void productSyncMetadataTests() {
  Product buildSyncProduct({
    bool active = true,
    MasterSyncStatus syncStatus = MasterSyncStatus.pending,
    int serverVersion = 0,
    DateTime? deletedAt,
  }) {
    return Product(
      id: 'sync-product-001',
      sku: 'SYNC-SKU-001',
      productName: 'Sync Product',
      cost: 10,
      retailPrice: 20,
      vat: 0,
      active: active,
      inventoryMode: ProductInventoryMode.direct,
      costingMethod: ProductCostingMethod.manual,
      createdAt: DateTime.utc(
        2026,
        9,
        4,
      ),
      updatedAt: DateTime.utc(
        2026,
        9,
        5,
      ),
      syncStatus: syncStatus,
      serverVersion: serverVersion,
      deletedAt: deletedAt,
    );
  }

  group('Product sync metadata', () {
    test('defaults to Pending version zero', () {
      final Product product = buildSyncProduct();

      expect(
        product.syncStatus,
        MasterSyncStatus.pending,
      );

      expect(product.serverVersion, 0);
      expect(product.deletedAt, isNull);
      expect(product.isDeleted, isFalse);
    });

    test('round-trips SQLite sync metadata', () {
      final Product original = buildSyncProduct(
        active: false,
        syncStatus: MasterSyncStatus.error,
        serverVersion: 6,
        deletedAt: DateTime.utc(
          2026,
          9,
          6,
        ),
      );

      final Product restored = Product.fromSqlite(
        original.toSqlite(),
      );

      expect(
        restored.syncStatus,
        MasterSyncStatus.error,
      );

      expect(restored.serverVersion, 6);
      expect(restored.isDeleted, isTrue);
      expect(restored.active, isFalse);
    });

    test('round-trips Firebase sync metadata', () {
      final Product original = buildSyncProduct(
        syncStatus: MasterSyncStatus.synced,
        serverVersion: 8,
      );

      final Product restored = Product.fromFirebase(
        original.id,
        Map<Object?, Object?>.from(
          original.toFirebase(),
        ),
      );

      expect(
        restored.syncStatus,
        MasterSyncStatus.synced,
      );

      expect(restored.serverVersion, 8);
    });

    test('rejects negative server version', () {
      expect(
        () => buildSyncProduct(
          serverVersion: -1,
        ).validate(),
        throwsFormatException,
      );
    });

    test('rejects active tombstone', () {
      expect(
        () => buildSyncProduct(
          active: true,
          deletedAt: DateTime.utc(
            2026,
            9,
            6,
          ),
        ).validate(),
        throwsFormatException,
      );
    });

    test('copyWith clears tombstone', () {
      final Product deleted = buildSyncProduct(
        active: false,
        deletedAt: DateTime.utc(
          2026,
          9,
          6,
        ),
      );

      final Product restored = deleted.copyWith(
        active: true,
        clearDeletedAt: true,
        syncStatus: MasterSyncStatus.pending,
      );

      expect(restored.deletedAt, isNull);
      expect(restored.isDeleted, isFalse);
      expect(restored.active, isTrue);
    });
  });
}
