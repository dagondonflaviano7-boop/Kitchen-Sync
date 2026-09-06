import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/daos/sale_consumption_dao.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v9.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  const SaleConsumptionDao dao = SaleConsumptionDao();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (
        Database db,
        int version,
      ) async {
        await createVersion8InventorySchema(db);
        await applyMigrationV9(db);
      },
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SaleConsumptionDao SQLite execution', () {
    test(
      'DIRECT consumption deducts Product inventory '
      'and inserts an audit movement',
      () async {
        await insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        final SaleConsumptionPlan plan = buildDirectConsumptionPlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        final Map<String, Object?> balance = await getProductBalance(database);

        expect(
          balance['quantity'],
          8,
        );
        expect(
          balance['average_cost'],
          50,
        );
        expect(
          balance['updated_at'],
          testOccurredAt.toIso8601String(),
        );

        final List<Map<String, Object?>> movements = await database.query(
          'inventory_movements',
        );

        expect(
          movements,
          hasLength(1),
        );

        final Map<String, Object?> movement = movements.single;

        expect(
          movement['id'],
          directConsumptionKey,
        );
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
          -2,
        );
        expect(
          movement['before_quantity'],
          10,
        );
        expect(
          movement['after_quantity'],
          8,
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
          movement['idempotency_key'],
          directConsumptionKey,
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
          50,
        );
        expect(
          movement['reversal_of_movement_id'],
          isNull,
        );
        expect(
          movement['user_id'],
          'user-001',
        );
        expect(
          movement['device_id'],
          'device-001',
        );
        expect(
          movement['created_at'],
          testOccurredAt.toIso8601String(),
        );
      },
    );

    test(
      'repeated DIRECT execution is idempotent',
      () async {
        await insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        final SaleConsumptionPlan plan = buildDirectConsumptionPlan();

        await dao.executePlan(
          database,
          plan,
        );

        await dao.executePlan(
          database,
          plan,
        );

        final Map<String, Object?> balance = await getProductBalance(database);

        expect(
          balance['quantity'],
          8,
        );

        final int movementCount = await countRows(
          database,
          'inventory_movements',
        );

        expect(
          movementCount,
          1,
        );
      },
    );

    test(
      'DIRECT consumption rejects missing Product inventory',
      () async {
        await expectLater(
          dao.executePlan(
            database,
            buildDirectConsumptionPlan(),
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Product Inventory record was not found.',
            ),
          ),
        );

        expect(
          await countRows(
            database,
            'inventory_movements',
          ),
          0,
        );
      },
    );

    test(
      'RECIPE consumption deducts all Ingredient balances '
      'and inserts audit movements',
      () async {
        await insertIngredientBalance(
          database,
          id: 'ingredient-inventory-001',
          ingredientId: 'ingredient-001',
          quantity: 5,
          averageCost: 20,
        );

        await insertIngredientBalance(
          database,
          id: 'ingredient-inventory-002',
          ingredientId: 'ingredient-002',
          quantity: 8,
          averageCost: 5,
        );

        final SaleConsumptionPlan plan = buildRecipeConsumptionPlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        final Map<String, Object?> firstBalance = await getIngredientBalance(
          database,
          'ingredient-001',
        );

        final Map<String, Object?> secondBalance = await getIngredientBalance(
          database,
          'ingredient-002',
        );

        expect(
          firstBalance['quantity'],
          4.5,
        );
        expect(
          firstBalance['average_cost'],
          20,
        );

        expect(
          secondBalance['quantity'],
          7,
        );
        expect(
          secondBalance['average_cost'],
          5,
        );

        final List<Map<String, Object?>> movements = await database.query(
          'ingredient_movements',
          orderBy: 'item_id',
        );

        expect(
          movements,
          hasLength(2),
        );

        expect(
          movements[0]['item_id'],
          'ingredient-001',
        );
        expect(
          movements[0]['quantity'],
          -0.5,
        );
        expect(
          movements[0]['before_quantity'],
          5,
        );
        expect(
          movements[0]['after_quantity'],
          4.5,
        );
        expect(
          movements[0]['unit_cost_snapshot'],
          20,
        );

        expect(
          movements[1]['item_id'],
          'ingredient-002',
        );
        expect(
          movements[1]['quantity'],
          -1,
        );
        expect(
          movements[1]['before_quantity'],
          8,
        );
        expect(
          movements[1]['after_quantity'],
          7,
        );
        expect(
          movements[1]['unit_cost_snapshot'],
          5,
        );
      },
    );

    test(
      'repeated RECIPE execution is idempotent',
      () async {
        await insertIngredientBalance(
          database,
          id: 'ingredient-inventory-001',
          ingredientId: 'ingredient-001',
          quantity: 5,
          averageCost: 20,
        );

        await insertIngredientBalance(
          database,
          id: 'ingredient-inventory-002',
          ingredientId: 'ingredient-002',
          quantity: 8,
          averageCost: 5,
        );

        final SaleConsumptionPlan plan = buildRecipeConsumptionPlan();

        await dao.executePlan(
          database,
          plan,
        );

        await dao.executePlan(
          database,
          plan,
        );

        final Map<String, Object?> firstBalance = await getIngredientBalance(
          database,
          'ingredient-001',
        );

        final Map<String, Object?> secondBalance = await getIngredientBalance(
          database,
          'ingredient-002',
        );

        expect(
          firstBalance['quantity'],
          4.5,
        );
        expect(
          secondBalance['quantity'],
          7,
        );

        expect(
          await countRows(
            database,
            'ingredient_movements',
          ),
          2,
        );
      },
    );

    test(
      'NONE plan performs no balance or movement writes',
      () async {
        await insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        await dao.executePlan(
          database,
          buildNonePlan(),
        );

        final Map<String, Object?> balance = await getProductBalance(database);

        expect(
          balance['quantity'],
          10,
        );
        expect(
          balance['average_cost'],
          50,
        );

        expect(
          await countRows(
            database,
            'inventory_movements',
          ),
          0,
        );

        expect(
          await countRows(
            database,
            'ingredient_movements',
          ),
          0,
        );
      },
    );

    test(
      'RECIPE failure rolls back earlier Ingredient writes '
      'when executed inside one transaction',
      () async {
        await insertIngredientBalance(
          database,
          id: 'ingredient-inventory-001',
          ingredientId: 'ingredient-001',
          quantity: 5,
          averageCost: 20,
        );

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await dao.executePlan(
                transaction,
                buildRecipeConsumptionPlan(),
              );
            },
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Ingredient Inventory record was not found.',
            ),
          ),
        );

        final Map<String, Object?> firstBalance = await getIngredientBalance(
          database,
          'ingredient-001',
        );

        expect(
          firstBalance['quantity'],
          5,
        );

        expect(
          await countRows(
            database,
            'ingredient_movements',
          ),
          0,
        );
      },
    );

    test(
      'Product restoration increases inventory '
      'and links the original movement',
      () async {
        await insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        await dao.executePlan(
          database,
          buildDirectConsumptionPlan(),
        );

        await dao.executePlan(
          database,
          buildDirectRestorationPlan(),
        );

        final Map<String, Object?> balance = await getProductBalance(database);

        expect(
          balance['quantity'],
          10,
        );
        expect(
          balance['average_cost'],
          50,
        );

        final List<Map<String, Object?>> movements = await database.query(
          'inventory_movements',
          orderBy: 'movement_type',
        );

        expect(
          movements,
          hasLength(2),
        );

        final Map<String, Object?> restoration = movements.firstWhere(
          (Map<String, Object?> row) {
            return row['movement_type'] == 'RESTORE';
          },
        );

        expect(
          restoration['quantity'],
          2,
        );
        expect(
          restoration['before_quantity'],
          8,
        );
        expect(
          restoration['after_quantity'],
          10,
        );
        expect(
          restoration['reversal_of_movement_id'],
          directConsumptionKey,
        );
      },
    );

    test(
      'Product restoration rejects a missing original movement',
      () async {
        await insertProductBalance(
          database,
          quantity: 8,
          averageCost: 50,
        );

        await expectLater(
          dao.executePlan(
            database,
            buildDirectRestorationPlan(),
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Original movement was not found.',
            ),
          ),
        );

        final Map<String, Object?> balance = await getProductBalance(database);

        expect(
          balance['quantity'],
          8,
        );

        expect(
          await countRows(
            database,
            'inventory_movements',
          ),
          0,
        );
      },
    );

    test(
      'Product restoration cannot restore '
      'the same original movement twice',
      () async {
        await insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        await dao.executePlan(
          database,
          buildDirectConsumptionPlan(),
        );

        await dao.executePlan(
          database,
          buildDirectRestorationPlan(),
        );

        await expectLater(
          dao.executePlan(
            database,
            buildSecondDirectRestorationPlan(),
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Movement has already been restored.',
            ),
          ),
        );

        final Map<String, Object?> balance = await getProductBalance(database);

        expect(
          balance['quantity'],
          10,
        );

        expect(
          await countRows(
            database,
            'inventory_movements',
          ),
          2,
        );
      },
    );
  });
}

final DateTime testOccurredAt = DateTime.utc(
  2026,
  9,
  6,
  8,
);

const String directConsumptionKey = 'SALE:sale-001:sale-item-001:'
    'PRODUCT:product-001:consume';

const String directRestorationKey = 'SALE:sale-001:sale-item-001:'
    'PRODUCT:product-001:restore';

SaleConsumptionRequest buildRequest() {
  return SaleConsumptionRequest(
    saleId: 'sale-001',
    saleItemId: 'sale-item-001',
    storeId: 'store-001',
    productId: 'product-001',
    productSku: 'SKU-001',
    quantitySold: 2,
    occurredAt: testOccurredAt,
    performedBy: 'user-001',
    deviceId: 'device-001',
  );
}

SaleConsumptionPlan buildDirectConsumptionPlan() {
  return SaleConsumptionPlan(
    request: buildRequest(),
    inventoryMode: ProductInventoryMode.direct,
    movements: <PlannedInventoryMovement>[
      buildDirectMovement(),
    ],
    expectedCost: 100,
  );
}

SaleConsumptionPlan buildDirectRestorationPlan() {
  return SaleConsumptionPlan(
    request: buildRequest(),
    inventoryMode: ProductInventoryMode.direct,
    movements: <PlannedInventoryMovement>[
      buildDirectMovement(
        idempotencyKey: directRestorationKey,
        operation: ConsumptionOperation.restore,
        quantityDelta: 2,
        reversalOfMovementId: directConsumptionKey,
      ),
    ],
    expectedCost: 100,
  );
}

SaleConsumptionPlan buildSecondDirectRestorationPlan() {
  return SaleConsumptionPlan(
    request: buildRequest(),
    inventoryMode: ProductInventoryMode.direct,
    movements: <PlannedInventoryMovement>[
      buildDirectMovement(
        idempotencyKey: '$directRestorationKey:second',
        operation: ConsumptionOperation.restore,
        quantityDelta: 2,
        reversalOfMovementId: directConsumptionKey,
      ),
    ],
    expectedCost: 100,
  );
}

PlannedInventoryMovement buildDirectMovement({
  String idempotencyKey = directConsumptionKey,
  ConsumptionOperation operation = ConsumptionOperation.consume,
  double quantityDelta = -2,
  String? reversalOfMovementId,
}) {
  return PlannedInventoryMovement(
    idempotencyKey: idempotencyKey,
    operation: operation,
    itemType: ConsumptionItemType.product,
    itemId: 'product-001',
    itemCode: 'SKU-001',
    unitCode: 'EACH',
    quantityDelta: quantityDelta,
    unitCostSnapshot: 50,
    sourceSaleId: 'sale-001',
    sourceSaleItemId: 'sale-item-001',
    storeId: 'store-001',
    performedBy: 'user-001',
    deviceId: 'device-001',
    occurredAt: testOccurredAt,
    reversalOfMovementId: reversalOfMovementId,
  );
}

SaleConsumptionPlan buildRecipeConsumptionPlan() {
  return SaleConsumptionPlan(
    request: buildRequest(),
    inventoryMode: ProductInventoryMode.recipe,
    movements: <PlannedInventoryMovement>[
      buildIngredientMovement(
        ingredientId: 'ingredient-001',
        ingredientCode: 'ING-001',
        recipeIngredientId: 'recipe-line-001',
        quantityDelta: -0.5,
        unitCostSnapshot: 20,
      ),
      buildIngredientMovement(
        ingredientId: 'ingredient-002',
        ingredientCode: 'ING-002',
        recipeIngredientId: 'recipe-line-002',
        quantityDelta: -1,
        unitCostSnapshot: 5,
      ),
    ],
    expectedCost: 15,
  );
}

PlannedInventoryMovement buildIngredientMovement({
  required String ingredientId,
  required String ingredientCode,
  required String recipeIngredientId,
  required double quantityDelta,
  required double unitCostSnapshot,
}) {
  return PlannedInventoryMovement(
    idempotencyKey: 'SALE:sale-001:'
        'sale-item-001:'
        'INGREDIENT:$ingredientId',
    operation: ConsumptionOperation.consume,
    itemType: ConsumptionItemType.ingredient,
    itemId: ingredientId,
    itemCode: ingredientCode,
    unitCode: 'KG',
    quantityDelta: quantityDelta,
    unitCostSnapshot: unitCostSnapshot,
    sourceSaleId: 'sale-001',
    sourceSaleItemId: 'sale-item-001',
    storeId: 'store-001',
    performedBy: 'user-001',
    deviceId: 'device-001',
    occurredAt: testOccurredAt,
    recipeId: 'recipe-001',
    recipeIngredientId: recipeIngredientId,
  );
}

SaleConsumptionPlan buildNonePlan() {
  return SaleConsumptionPlan(
    request: buildRequest(),
    inventoryMode: ProductInventoryMode.none,
    movements: const <PlannedInventoryMovement>[],
    expectedCost: 0,
  );
}

Future<void> createVersion8InventorySchema(
  Database db,
) async {
  await db.execute(
    '''
    CREATE TABLE inventory (
      id TEXT PRIMARY KEY,
      store_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      average_cost REAL NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      UNIQUE(store_id, product_id)
    )
    ''',
  );

  await db.execute(
    '''
    CREATE TABLE ingredient_inventory (
      id TEXT PRIMARY KEY,
      store_id TEXT NOT NULL,
      ingredient_id TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 0,
      average_cost REAL NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      UNIQUE(store_id, ingredient_id)
    )
    ''',
  );

  await db.execute(
    '''
    CREATE TABLE inventory_movements (
      id TEXT PRIMARY KEY,
      store_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      before_quantity REAL NOT NULL,
      after_quantity REAL NOT NULL,
      movement_type TEXT NOT NULL,
      reference_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      remarks TEXT
    )
    ''',
  );

  await db.execute(
    '''
    CREATE TABLE ingredient_movements (
      id TEXT PRIMARY KEY,
      store_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      before_quantity REAL NOT NULL,
      after_quantity REAL NOT NULL,
      movement_type TEXT NOT NULL,
      reference_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      device_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      remarks TEXT
    )
    ''',
  );

  await db.execute(
    '''
    CREATE INDEX idx_movements_reference
    ON inventory_movements(reference_id)
    ''',
  );

  await db.execute(
    '''
    CREATE INDEX idx_ingredient_movements_reference
    ON ingredient_movements(reference_id)
    ''',
  );
}

Future<void> applyMigrationV9(
  Database database,
) async {
  for (final String statement in migrationV9) {
    await database.execute(statement);
  }
}

Future<void> insertProductBalance(
  Database database, {
  required double quantity,
  required double averageCost,
}) async {
  await database.insert(
    'inventory',
    <String, Object?>{
      'id': 'inventory-001',
      'store_id': 'store-001',
      'product_id': 'product-001',
      'quantity': quantity,
      'average_cost': averageCost,
      'updated_at': '2026-09-05T00:00:00.000Z',
    },
  );
}

Future<void> insertIngredientBalance(
  Database database, {
  required String id,
  required String ingredientId,
  required double quantity,
  required double averageCost,
}) async {
  await database.insert(
    'ingredient_inventory',
    <String, Object?>{
      'id': id,
      'store_id': 'store-001',
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'average_cost': averageCost,
      'updated_at': '2026-09-05T00:00:00.000Z',
    },
  );
}

Future<Map<String, Object?>> getProductBalance(
  Database database,
) async {
  return (await database.query(
    'inventory',
    where: 'store_id = ? AND product_id = ?',
    whereArgs: const <Object?>[
      'store-001',
      'product-001',
    ],
  ))
      .single;
}

Future<Map<String, Object?>> getIngredientBalance(
  Database database,
  String ingredientId,
) async {
  return (await database.query(
    'ingredient_inventory',
    where: 'store_id = ? AND ingredient_id = ?',
    whereArgs: <Object?>[
      'store-001',
      ingredientId,
    ],
  ))
      .single;
}

Future<int> countRows(
  Database database,
  String table,
) async {
  final List<Map<String, Object?>> result = await database.rawQuery(
    'SELECT COUNT(*) AS row_count FROM $table',
  );

  final Object? value = result.single['row_count'];

  if (value is int) {
    return value;
  }

  return int.parse(
    value.toString(),
  );
}
