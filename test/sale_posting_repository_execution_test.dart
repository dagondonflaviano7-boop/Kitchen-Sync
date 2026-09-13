import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/daos/product_dao.dart';
import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/data/repositories/sale_posting_repository.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_posting.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late String databasePath;

  const ProductDao productDao = ProductDao();
  const RecipeDao recipeDao = RecipeDao();
  const SalePostingRepository repository = SalePostingRepository();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    databasePath = path.join(
      await getDatabasesPath(),
      AppConstants.databaseName,
    );
  });

  setUp(() async {
    await AppDatabase.instance.close();
    await databaseFactoryFfi.deleteDatabase(
      databasePath,
    );

    database = await AppDatabase.instance.database;
  });

  tearDown(() async {
    await AppDatabase.instance.close();

    await databaseFactoryFfi.deleteDatabase(
      databasePath,
    );
  });

  Product buildProduct({
    String id = 'product-001',
    String sku = 'SKU-001',
    String productName = 'Test Product',
    double cost = 25,
    double retailPrice = 100,
    bool active = true,
    ProductInventoryMode inventoryMode = ProductInventoryMode.direct,
    String? recipeId,
  }) {
    return Product(
      id: id,
      sku: sku,
      productName: productName,
      cost: cost,
      retailPrice: retailPrice,
      vat: 0,
      active: active,
      inventoryMode: inventoryMode,
      recipeId: recipeId,
      createdAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
      updatedAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
    );
  }

  SalePostingItem buildItem({
    String id = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'SKU-001',
    String productName = 'Test Product',
    double quantity = 2,
    double sellingPrice = 100,
    double discount = 20,
  }) {
    return SalePostingItem(
      id: id,
      productId: productId,
      productSku: productSku,
      productName: productName,
      quantity: quantity,
      sellingPrice: sellingPrice,
      discount: discount,
    );
  }

  SalePostingPayment buildPayment({
    String id = 'payment-001',
    String paymentType = 'CASH',
    double amount = 180,
  }) {
    return SalePostingPayment(
      id: id,
      paymentType: paymentType,
      amount: amount,
      createdAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
    );
  }

  SalePostingRequest buildRequest({
    String saleId = 'sale-001',
    String transactionNumber = 'TXN-0001',
    String storeId = 'store-001',
    String deviceId = 'device-001',
    String cashierId = 'user-001',
    List<SalePostingItem>? items,
    List<SalePostingPayment>? payments,
  }) {
    return SalePostingRequest(
      saleId: saleId,
      transactionNumber: transactionNumber,
      storeId: storeId,
      deviceId: deviceId,
      cashierId: cashierId,
      occurredAt: DateTime.utc(
        2026,
        9,
        13,
        8,
      ),
      items: items ??
          <SalePostingItem>[
            buildItem(),
          ],
      payments: payments ??
          <SalePostingPayment>[
            buildPayment(),
          ],
    );
  }

  Future<void> insertProduct(
    Product product,
  ) async {
    await productDao.upsert(
      database,
      product,
    );
  }

  Future<void> insertProductInventory({
    String id = 'inventory-001',
    String storeId = 'store-001',
    String productId = 'product-001',
    double quantity = 20,
    double averageCost = 25,
  }) async {
    await database.insert(
      'inventory',
      <String, Object?>{
        'id': id,
        'store_id': storeId,
        'product_id': productId,
        'quantity': quantity,
        'average_cost': averageCost,
        'updated_at': DateTime.utc(
          2026,
          9,
          13,
          7,
        ).toIso8601String(),
      },
    );
  }

  Future<void> insertIngredient({
    String id = 'ingredient-001',
    String ingredientSku = 'ING-001',
    String ingredientName = 'Recipe Ingredient',
    String usageUnitCode = 'GRAM',
    double conversionFactor = 1,
    double cost = 0.05,
    bool active = true,
  }) async {
    await database.insert(
      'ingredients',
      <String, Object?>{
        'id': id,
        'ingredient_sku': ingredientSku.trim().toUpperCase(),
        'ingredient_name': ingredientName.trim(),
        'category': 'OTHER',
        'supplier_id': null,
        'supplier_name': null,
        'unit_of_measure': usageUnitCode.trim().toUpperCase(),
        'purchase_unit': usageUnitCode.trim().toUpperCase(),
        'conversion_factor': conversionFactor,
        'cost': cost,
        'minimum_stock': 0.0,
        'maximum_stock': null,
        'active': active ? 1 : 0,
        'created_at': DateTime.utc(
          2026,
          9,
          13,
          7,
        ).toIso8601String(),
        'updated_at': DateTime.utc(
          2026,
          9,
          13,
          7,
        ).toIso8601String(),
      },
    );
  }

  Future<void> insertIngredientInventory({
    String id = 'ingredient-inventory-001',
    String storeId = 'store-001',
    String ingredientId = 'ingredient-001',
    double quantity = 500,
    double averageCost = 0.05,
  }) async {
    await database.insert(
      'ingredient_inventory',
      <String, Object?>{
        'id': id,
        'store_id': storeId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'average_cost': averageCost,
        'updated_at': DateTime.utc(
          2026,
          9,
          13,
          7,
        ).toIso8601String(),
      },
    );
  }

  Recipe buildRecipe({
    String id = 'recipe-001',
    bool active = true,
  }) {
    return Recipe(
      id: id,
      recipeCode: 'RCP-001',
      recipeName: 'Test Recipe',
      category: RecipeCategory.mainDish,
      yieldQuantity: 2,
      yieldUnitCode: 'EACH',
      active: active,
      ingredients: <RecipeIngredient>[
        RecipeIngredient(
          id: 'recipe-line-001',
          recipeId: id,
          ingredientId: 'ingredient-001',
          ingredientSku: 'ING-001',
          ingredientName: 'Recipe Ingredient',
          usageUnitCode: 'GRAM',
          quantityRequired: 100,
          costPerUsageUnit: 0.05,
        ),
      ],
      createdAt: DateTime.utc(
        2026,
        9,
        13,
        7,
      ),
      updatedAt: DateTime.utc(
        2026,
        9,
        13,
        7,
      ),
      createdBy: 'user-001',
      updatedBy: 'user-001',
    );
  }

  Future<void> insertRecipe(
    Recipe recipe,
  ) async {
    await recipeDao.insertRecipe(
      database,
      recipe,
    );
  }

  Future<double> ingredientInventoryQuantity({
    String storeId = 'store-001',
    String ingredientId = 'ingredient-001',
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredient_inventory',
      columns: const <String>[
        'quantity',
      ],
      where: 'store_id = ? AND ingredient_id = ?',
      whereArgs: <Object?>[
        storeId,
        ingredientId,
      ],
      limit: 1,
    );

    return (rows.single['quantity'] as num).toDouble();
  }

  Future<int> tableCount(
    String table,
  ) async {
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS row_count FROM $table',
    );

    return (rows.single['row_count'] as num).toInt();
  }

  Future<double> productInventoryQuantity({
    String storeId = 'store-001',
    String productId = 'product-001',
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'inventory',
      columns: const <String>[
        'quantity',
      ],
      where: 'store_id = ? AND product_id = ?',
      whereArgs: <Object?>[
        storeId,
        productId,
      ],
      limit: 1,
    );

    return (rows.single['quantity'] as num).toDouble();
  }

  group('Sale Posting Repository execution', () {
    test(
      'posts DIRECT sale and deducts Product inventory',
      () async {
        await insertProduct(
          buildProduct(),
        );

        await insertProductInventory();

        await repository.postSale(
          buildRequest(),
        );

        expect(
          await tableCount('sales'),
          1,
        );

        expect(
          await tableCount('sale_items'),
          1,
        );

        expect(
          await tableCount('payments'),
          1,
        );

        expect(
          await productInventoryQuantity(),
          18,
        );

        expect(
          await tableCount('inventory_movements'),
          1,
        );

        expect(
          await tableCount('ingredient_movements'),
          0,
        );

        final Map<String, Object?> movement =
            (await database.query('inventory_movements')).single;

        expect(
          movement['store_id'],
          'store-001',
        );

        expect(
          movement['item_id'],
          'product-001',
        );

        expect(
          movement['quantity'],
          -2.0,
        );

        expect(
          movement['before_quantity'],
          20.0,
        );

        expect(
          movement['after_quantity'],
          18.0,
        );

        expect(
          movement['movement_type'],
          'CONSUME',
        );

        expect(
          movement['reference_id'],
          'sale-001',
        );

        expect(
          movement['source_sale_id'],
          'sale-001',
        );

        expect(
          movement['source_sale_item_id'],
          'sale-item-001',
        );

        expect(
          movement['unit_cost_snapshot'],
          25.0,
        );

        expect(
          movement['idempotency_key'],
          'SALE:sale-001:sale-item-001:'
          'PRODUCT:product-001:CONSUME',
        );
      },
    );

    test(
      'posts NONE sale without inventory movement',
      () async {
        await insertProduct(
          buildProduct(
            inventoryMode: ProductInventoryMode.none,
          ),
        );

        await repository.postSale(
          buildRequest(),
        );

        expect(
          await tableCount('sales'),
          1,
        );

        expect(
          await tableCount('sale_items'),
          1,
        );

        expect(
          await tableCount('payments'),
          1,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await tableCount('ingredient_movements'),
          0,
        );

        expect(
          await tableCount('inventory'),
          0,
        );
      },
    );

    test(
      'rejects duplicate sale without another deduction',
      () async {
        await insertProduct(
          buildProduct(),
        );

        await insertProductInventory();

        final SalePostingRequest first = buildRequest();

        final SalePostingRequest duplicate = buildRequest(
          saleId: 'sale-002',
          transactionNumber: ' txn-0001 ',
          items: <SalePostingItem>[
            buildItem(
              id: 'sale-item-002',
            ),
          ],
          payments: <SalePostingPayment>[
            buildPayment(
              id: 'payment-002',
            ),
          ],
        );

        await repository.postSale(first);

        await expectLater(
          repository.postSale(duplicate),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          1,
        );

        expect(
          await tableCount('sale_items'),
          1,
        );

        expect(
          await tableCount('payments'),
          1,
        );

        expect(
          await tableCount('inventory_movements'),
          1,
        );

        expect(
          await productInventoryQuantity(),
          18,
        );
      },
    );

    test(
      'rolls back when Product does not exist',
      () async {
        await expectLater(
          repository.postSale(
            buildRequest(),
          ),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await tableCount('ingredient_movements'),
          0,
        );
      },
    );

    test(
      'treats inactive Product as unavailable',
      () async {
        await insertProduct(
          buildProduct(
            active: false,
          ),
        );

        await insertProductInventory();

        await expectLater(
          repository.postSale(
            buildRequest(),
          ),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await productInventoryQuantity(),
          20,
        );
      },
    );

    test(
      'rolls back sale records when Product inventory is missing',
      () async {
        await insertProduct(
          buildProduct(),
        );

        await expectLater(
          repository.postSale(
            buildRequest(),
          ),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await tableCount('inventory'),
          0,
        );
      },
    );

    test(
      'rolls back earlier movement when a later item fails',
      () async {
        await insertProduct(
          buildProduct(),
        );

        await insertProduct(
          buildProduct(
            id: 'product-002',
            sku: 'SKU-002',
            productName: 'Second Product',
          ),
        );

        await insertProductInventory();

        final SalePostingRequest request = buildRequest(
          items: <SalePostingItem>[
            buildItem(),
            buildItem(
              id: 'sale-item-002',
              productId: 'product-002',
              productSku: 'SKU-002',
              productName: 'Second Product',
              quantity: 1,
              sellingPrice: 50,
              discount: 0,
            ),
          ],
          payments: <SalePostingPayment>[
            buildPayment(
              amount: 230,
            ),
          ],
        );

        await expectLater(
          repository.postSale(request),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await productInventoryQuantity(),
          20,
        );
      },
    );
    test(
      'posts RECIPE sale and deducts Ingredient inventory',
      () async {
        await insertIngredient();
        await insertIngredientInventory();

        await insertRecipe(
          buildRecipe(),
        );

        await insertProduct(
          buildProduct(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
        );

        await repository.postSale(
          buildRequest(),
        );

        expect(
          await tableCount('sales'),
          1,
        );

        expect(
          await tableCount('sale_items'),
          1,
        );

        expect(
          await tableCount('payments'),
          1,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await tableCount('ingredient_movements'),
          1,
        );

        expect(
          await ingredientInventoryQuantity(),
          400,
        );

        final Map<String, Object?> movement =
            (await database.query('ingredient_movements')).single;

        expect(
          movement['store_id'],
          'store-001',
        );

        expect(
          movement['item_id'],
          'ingredient-001',
        );

        expect(
          movement['quantity'],
          -100.0,
        );

        expect(
          movement['before_quantity'],
          500.0,
        );

        expect(
          movement['after_quantity'],
          400.0,
        );

        expect(
          movement['movement_type'],
          'CONSUME',
        );

        expect(
          movement['reference_id'],
          'sale-001',
        );

        expect(
          movement['source_sale_id'],
          'sale-001',
        );

        expect(
          movement['source_sale_item_id'],
          'sale-item-001',
        );

        expect(
          movement['recipe_id'],
          'recipe-001',
        );

        expect(
          movement['recipe_ingredient_id'],
          'recipe-line-001',
        );

        expect(
          movement['unit_cost_snapshot'],
          0.05,
        );

        expect(
          movement['idempotency_key'],
          'SALE:sale-001:sale-item-001:'
          'INGREDIENT:ingredient-001:'
          'recipe-line-001:CONSUME',
        );
      },
    );

    test(
      'rolls back when linked Recipe is missing',
      () async {
        await insertIngredient();
        await insertIngredientInventory();

        await insertProduct(
          buildProduct(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-missing',
          ),
        );

        await expectLater(
          repository.postSale(
            buildRequest(),
          ),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await tableCount('ingredient_movements'),
          0,
        );

        expect(
          await ingredientInventoryQuantity(),
          500,
        );
      },
    );

    test(
      'rolls back when Ingredient inventory is missing',
      () async {
        await insertIngredient();

        await insertRecipe(
          buildRecipe(),
        );

        await insertProduct(
          buildProduct(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
        );

        await expectLater(
          repository.postSale(
            buildRequest(),
          ),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('inventory_movements'),
          0,
        );

        expect(
          await tableCount('ingredient_movements'),
          0,
        );

        expect(
          await tableCount('ingredient_inventory'),
          0,
        );
      },
    );

    test(
      'rolls back prior Recipe movement when later Ingredient fails',
      () async {
        await insertIngredient();
        await insertIngredient(
          id: 'ingredient-002',
          ingredientSku: 'ING-002',
          ingredientName: 'Second Ingredient',
          usageUnitCode: 'ML',
          cost: 0.02,
        );

        await insertIngredientInventory();

        final Recipe recipe = Recipe(
          id: 'recipe-001',
          recipeCode: 'RCP-001',
          recipeName: 'Two Ingredient Recipe',
          category: RecipeCategory.mainDish,
          yieldQuantity: 2,
          yieldUnitCode: 'EACH',
          active: true,
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              id: 'recipe-line-001',
              recipeId: 'recipe-001',
              ingredientId: 'ingredient-001',
              ingredientSku: 'ING-001',
              ingredientName: 'Recipe Ingredient',
              usageUnitCode: 'GRAM',
              quantityRequired: 100,
              costPerUsageUnit: 0.05,
            ),
            RecipeIngredient(
              id: 'recipe-line-002',
              recipeId: 'recipe-001',
              ingredientId: 'ingredient-002',
              ingredientSku: 'ING-002',
              ingredientName: 'Second Ingredient',
              usageUnitCode: 'ML',
              quantityRequired: 50,
              costPerUsageUnit: 0.02,
            ),
          ],
          createdAt: DateTime.utc(
            2026,
            9,
            13,
            7,
          ),
          updatedAt: DateTime.utc(
            2026,
            9,
            13,
            7,
          ),
          createdBy: 'user-001',
          updatedBy: 'user-001',
        );

        await insertRecipe(recipe);

        await insertProduct(
          buildProduct(
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
        );

        await expectLater(
          repository.postSale(
            buildRequest(),
          ),
          throwsStateError,
        );

        expect(
          await tableCount('sales'),
          0,
        );

        expect(
          await tableCount('sale_items'),
          0,
        );

        expect(
          await tableCount('payments'),
          0,
        );

        expect(
          await tableCount('ingredient_movements'),
          0,
        );

        expect(
          await ingredientInventoryQuantity(),
          500,
        );
      },
    );
    test(
      'persists authoritative costing for mixed '
      'DIRECT RECIPE and NONE basket',
      () async {
        await insertProduct(
          buildProduct(
            id: 'product-001',
            sku: 'SKU-001',
            productName: 'Direct Product',
            cost: 25,
            inventoryMode: ProductInventoryMode.direct,
          ),
        );

        await insertProductInventory(
          id: 'inventory-direct',
          productId: 'product-001',
          quantity: 20,
          averageCost: 25,
        );

        await insertIngredient();
        await insertIngredientInventory();

        await insertRecipe(
          buildRecipe(),
        );

        await insertProduct(
          buildProduct(
            id: 'product-002',
            sku: 'SKU-002',
            productName: 'Recipe Product',
            cost: 0,
            retailPrice: 80,
            inventoryMode: ProductInventoryMode.recipe,
            recipeId: 'recipe-001',
          ),
        );

        await insertProduct(
          buildProduct(
            id: 'product-003',
            sku: 'SKU-003',
            productName: 'Non Inventory Product',
            cost: 0,
            retailPrice: 20,
            inventoryMode: ProductInventoryMode.none,
          ),
        );

        final SalePostingRequest request = buildRequest(
          saleId: 'sale-mixed-001',
          transactionNumber: 'TXN-MIXED-001',
          items: <SalePostingItem>[
            buildItem(
              id: 'sale-item-direct',
              productId: 'product-001',
              productSku: 'SKU-001',
              productName: 'Direct Product',
              quantity: 2,
              sellingPrice: 100,
              discount: 20,
            ),
            buildItem(
              id: 'sale-item-recipe',
              productId: 'product-002',
              productSku: 'SKU-002',
              productName: 'Recipe Product',
              quantity: 1,
              sellingPrice: 80,
              discount: 0,
            ),
            buildItem(
              id: 'sale-item-none',
              productId: 'product-003',
              productSku: 'SKU-003',
              productName: 'Non Inventory Product',
              quantity: 1,
              sellingPrice: 20,
              discount: 0,
            ),
          ],
          payments: <SalePostingPayment>[
            buildPayment(
              id: 'payment-mixed-001',
              amount: 280,
            ),
          ],
        );

        await repository.postSale(request);

        expect(
          await tableCount('sales'),
          1,
        );

        expect(
          await tableCount('sale_items'),
          3,
        );

        expect(
          await tableCount('payments'),
          1,
        );

        expect(
          await tableCount('inventory_movements'),
          1,
        );

        expect(
          await tableCount('ingredient_movements'),
          1,
        );

        final Map<String, Object?> sale = (await database.query(
          'sales',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'sale-mixed-001',
          ],
        ))
            .single;

        expect(
          sale['subtotal'],
          300.0,
        );

        expect(
          sale['discount'],
          20.0,
        );

        expect(
          sale['net_sales'],
          280.0,
        );

        expect(
          sale['grand_total'],
          280.0,
        );

        expect(
          sale['cost'],
          52.5,
        );

        expect(
          sale['cogs'],
          52.5,
        );

        expect(
          sale['gross_profit'],
          227.5,
        );

        expect(
          sale['gross_margin'],
          closeTo(
            81.25,
            0.0001,
          ),
        );

        final List<Map<String, Object?>> persistedItems = await database.query(
          'sale_items',
          where: 'transaction_id = ?',
          whereArgs: const <Object?>[
            'sale-mixed-001',
          ],
          orderBy: 'id',
        );

        expect(
          persistedItems,
          hasLength(3),
        );

        final Map<String, Object?> directItem = persistedItems.firstWhere(
          (Map<String, Object?> row) {
            return row['id'] == 'sale-item-direct';
          },
        );

        expect(
          directItem['unit_cost'],
          25.0,
        );

        expect(
          directItem['cogs'],
          50.0,
        );

        expect(
          directItem['recipe_version'],
          isNull,
        );

        expect(
          directItem['ingredient_cost_json'],
          isNull,
        );

        final Map<String, Object?> recipeItem = persistedItems.firstWhere(
          (Map<String, Object?> row) {
            return row['id'] == 'sale-item-recipe';
          },
        );

        expect(
          recipeItem['unit_cost'],
          2.5,
        );

        expect(
          recipeItem['cogs'],
          2.5,
        );

        expect(
          recipeItem['recipe_version'],
          isNull,
        );

        expect(
          recipeItem['ingredient_cost_json'],
          isNotNull,
        );

        final Map<String, dynamic> recipeCostJson = jsonDecode(
          recipeItem['ingredient_cost_json']! as String,
        ) as Map<String, dynamic>;

        expect(
          recipeCostJson['recipeId'],
          'recipe-001',
        );

        expect(
          recipeCostJson['totalIngredientCost'],
          2.5,
        );

        final List<dynamic> ingredientCosts =
            recipeCostJson['ingredients'] as List<dynamic>;

        expect(
          ingredientCosts,
          hasLength(1),
        );

        final Map<String, dynamic> ingredientCost =
            ingredientCosts.single as Map<String, dynamic>;

        expect(
          ingredientCost['recipeIngredientId'],
          'recipe-line-001',
        );

        expect(
          ingredientCost['ingredientId'],
          'ingredient-001',
        );

        expect(
          ingredientCost['ingredientCode'],
          'ING-001',
        );

        expect(
          ingredientCost['unitCode'],
          'GRAM',
        );

        expect(
          ingredientCost['quantity'],
          50.0,
        );

        expect(
          ingredientCost['unitCost'],
          0.05,
        );

        expect(
          ingredientCost['extendedCost'],
          2.5,
        );

        final Map<String, Object?> noneItem = persistedItems.firstWhere(
          (Map<String, Object?> row) {
            return row['id'] == 'sale-item-none';
          },
        );

        expect(
          noneItem['unit_cost'],
          0.0,
        );

        expect(
          noneItem['cogs'],
          0.0,
        );

        expect(
          noneItem['recipe_version'],
          isNull,
        );

        expect(
          noneItem['ingredient_cost_json'],
          isNull,
        );

        expect(
          await productInventoryQuantity(
            productId: 'product-001',
          ),
          18,
        );

        expect(
          await ingredientInventoryQuantity(),
          450,
        );

        final Map<String, Object?> productMovement = (await database.query(
          'inventory_movements',
        ))
            .single;

        expect(
          productMovement['source_sale_id'],
          'sale-mixed-001',
        );

        expect(
          productMovement['source_sale_item_id'],
          'sale-item-direct',
        );

        expect(
          productMovement['unit_cost_snapshot'],
          25.0,
        );

        final Map<String, Object?> ingredientMovement = (await database.query(
          'ingredient_movements',
        ))
            .single;

        expect(
          ingredientMovement['source_sale_id'],
          'sale-mixed-001',
        );

        expect(
          ingredientMovement['source_sale_item_id'],
          'sale-item-recipe',
        );

        expect(
          ingredientMovement['recipe_id'],
          'recipe-001',
        );

        expect(
          ingredientMovement['recipe_ingredient_id'],
          'recipe-line-001',
        );

        expect(
          ingredientMovement['unit_cost_snapshot'],
          0.05,
        );
      },
    );
  });
}
