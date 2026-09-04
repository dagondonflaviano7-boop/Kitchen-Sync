import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/daos/product_dao.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v7.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  const ProductDao productDao = ProductDao();

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (
          Database db,
          int version,
        ) async {
          await db.execute(
            migrationV1.firstWhere(
              (String statement) {
                return statement.contains(
                  'CREATE TABLE products',
                );
              },
            ),
          );

          for (final String statement in migrationV7) {
            await db.execute(statement);
          }
        },
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Product buildProduct({
    String id = 'product-001',
    String sku = 'SKU-001',
    String? barcode = '1234567890',
    String productName = 'Chicken Meal',
    ProductInventoryMode inventoryMode = ProductInventoryMode.direct,
    ProductCostingMethod costingMethod = ProductCostingMethod.manual,
    String? recipeId,
    bool active = true,
  }) {
    return Product(
      id: id,
      sku: sku,
      barcode: barcode,
      productName: productName,
      cost: 50,
      retailPrice: 100,
      vat: 12,
      active: active,
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

  test('upsert stores Product and Recipe ID', () async {
    final Product product = buildProduct(
      inventoryMode: ProductInventoryMode.recipe,
      costingMethod: ProductCostingMethod.ingredient,
      recipeId: 'recipe-001',
    );

    await productDao.upsert(
      database,
      product,
    );

    final Map<String, Object?> row = (await database.query(
      'products',
      where: 'id = ?',
      whereArgs: const <Object?>[
        'product-001',
      ],
    ))
        .single;

    expect(row['sku'], 'SKU-001');
    expect(row['recipe_id'], 'recipe-001');
    expect(row['inventory_mode'], 'RECIPE');
  });

  test('findById excludes inactive Product', () async {
    await productDao.upsert(
      database,
      buildProduct(
        active: false,
      ),
    );

    expect(
      await productDao.findById(
        database,
        'product-001',
      ),
      isNull,
    );

    expect(
      await productDao.findByIdIncludingInactive(
        database,
        'product-001',
      ),
      isNotNull,
    );
  });

  test('findBySku normalizes SKU', () async {
    await productDao.upsert(
      database,
      buildProduct(),
    );

    final Product? product = await productDao.findBySku(
      database,
      ' sku-001 ',
    );

    expect(product, isNotNull);
    expect(product!.id, 'product-001');
  });

  test('findByBarcode returns Product', () async {
    await productDao.upsert(
      database,
      buildProduct(),
    );

    final Product? product = await productDao.findByBarcode(
      database,
      '1234567890',
    );

    expect(product, isNotNull);
    expect(product!.sku, 'SKU-001');
  });

  test('search finds Product by name', () async {
    await productDao.upsert(
      database,
      buildProduct(),
    );

    final List<Product> products = await productDao.search(
      database,
      'chicken',
    );

    expect(products, hasLength(1));
    expect(
      products.single.productName,
      'Chicken Meal',
    );
  });

  test('search filters Inventory Mode', () async {
    await productDao.upsert(
      database,
      buildProduct(),
    );

    await productDao.upsert(
      database,
      buildProduct(
        id: 'product-002',
        sku: 'SKU-002',
        barcode: '9876543210',
        productName: 'Recipe Product',
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.ingredient,
        recipeId: 'recipe-001',
      ),
    );

    final List<Product> products = await productDao.search(
      database,
      '',
      inventoryMode: ProductInventoryMode.recipe,
    );

    expect(products, hasLength(1));
    expect(products.single.id, 'product-002');
  });

  test('duplicate checks support excluding ID', () async {
    await productDao.upsert(
      database,
      buildProduct(),
    );

    expect(
      await productDao.skuExists(
        database,
        'sku-001',
      ),
      isTrue,
    );

    expect(
      await productDao.skuExists(
        database,
        'sku-001',
        excludingId: 'product-001',
      ),
      isFalse,
    );

    expect(
      await productDao.barcodeExists(
        database,
        '1234567890',
      ),
      isTrue,
    );

    expect(
      await productDao.barcodeExists(
        database,
        '1234567890',
        excludingId: 'product-001',
      ),
      isFalse,
    );
  });

  test('setActive updates Product status', () async {
    await productDao.upsert(
      database,
      buildProduct(),
    );

    await productDao.setActive(
      database,
      'product-001',
      false,
      updatedAt: DateTime.utc(
        2026,
        9,
        5,
      ),
    );

    final Product? stored = await productDao.findByIdIncludingInactive(
      database,
      'product-001',
    );

    expect(stored, isNotNull);
    expect(stored!.active, isFalse);
  });

  test('findProductsByRecipeId returns links', () async {
    await productDao.upsert(
      database,
      buildProduct(
        inventoryMode: ProductInventoryMode.recipe,
        costingMethod: ProductCostingMethod.ingredient,
        recipeId: 'recipe-001',
      ),
    );

    final List<Product> products = await productDao.findProductsByRecipeId(
      database,
      'recipe-001',
    );

    expect(products, hasLength(1));
    expect(
      products.single.recipeId,
      'recipe-001',
    );
  });

  test('Product DAO validates writes', () async {
    final Product invalid = buildProduct(
      inventoryMode: ProductInventoryMode.recipe,
    );

    expect(
      () => productDao.upsert(
        database,
        invalid,
      ),
      throwsFormatException,
    );
  });
}
