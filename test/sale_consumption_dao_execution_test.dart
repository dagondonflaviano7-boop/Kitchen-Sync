import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/daos/sale_consumption_dao.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v9.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late SaleConsumptionDao dao;

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
        await _createVersion8InventorySchema(
          db,
        );

        for (final String statement in migrationV9) {
          await db.execute(statement);
        }
      },
    );

    dao = const SaleConsumptionDao();
  });

  tearDown(() async {
    await database.close();
  });

  group('Sale Consumption DAO SQLite execution', () {
    test(
      'executes DIRECT Product consumption',
      () async {
        await _insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        final SaleConsumptionPlan plan = _directPlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        final Map<String, Object?> balance = await _singleRow(
          database,
          table: 'inventory',
          where: '''
            store_id = ?
            AND product_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'product-001',
          ],
        );

        expect(
          balance['quantity'],
          8,
        );

        final Map<String, Object?> movement = await _singleRow(
          database,
          table: 'inventory_movements',
          where: 'idempotency_key = ?',
          whereArgs: const <Object?>[
            'SALE:sale-001:sale-item-001:'
                'PRODUCT:product-001:consume',
          ],
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
          movement['source_sale_id'],
          'sale-001',
        );
        expect(
          movement['source_sale_item_id'],
          'sale-item-001',
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
          movement['unit_cost_snapshot'],
          50,
        );
        expect(
          movement['reversal_of_movement_id'],
          isNull,
        );
      },
    );

    test(
      'does not apply duplicate DIRECT movement twice',
      () async {
        await _insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        final SaleConsumptionPlan plan = _directPlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        final Map<String, Object?> balance = await _singleRow(
          database,
          table: 'inventory',
          where: '''
            store_id = ?
            AND product_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'product-001',
          ],
        );

        expect(
          balance['quantity'],
          8,
        );

        final int movementCount = await _countRows(
          database,
          table: 'inventory_movements',
        );

        expect(
          movementCount,
          1,
        );

        expect(
          await dao.hasProcessedMovement(
            database,
            plan.movements.single,
          ),
          isTrue,
        );
      },
    );

    test(
      'executes RECIPE Ingredient consumption',
      () async {
        await _insertIngredientBalance(
          database,
          id: 'ingredient-inventory-001',
          ingredientId: 'ingredient-001',
          quantity: 5,
          averageCost: 20,
        );

        await _insertIngredientBalance(
          database,
          id: 'ingredient-inventory-002',
          ingredientId: 'ingredient-002',
          quantity: 8,
          averageCost: 5,
        );

        final SaleConsumptionPlan plan = _recipePlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        final Map<String, Object?> firstBalance = await _singleRow(
          database,
          table: 'ingredient_inventory',
          where: '''
            store_id = ?
            AND ingredient_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'ingredient-001',
          ],
        );

        final Map<String, Object?> secondBalance = await _singleRow(
          database,
          table: 'ingredient_inventory',
          where: '''
            store_id = ?
            AND ingredient_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'ingredient-002',
          ],
        );

        expect(
          firstBalance['quantity'],
          4.5,
        );
        expect(
          secondBalance['quantity'],
          7,
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
      'does not apply duplicate RECIPE movements twice',
      () async {
        await _insertIngredientBalance(
          database,
          id: 'ingredient-inventory-001',
          ingredientId: 'ingredient-001',
          quantity: 5,
          averageCost: 20,
        );

        await _insertIngredientBalance(
          database,
          id: 'ingredient-inventory-002',
          ingredientId: 'ingredient-002',
          quantity: 8,
          averageCost: 5,
        );

        final SaleConsumptionPlan plan = _recipePlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        final Map<String, Object?> firstBalance = await _singleRow(
          database,
          table: 'ingredient_inventory',
          where: '''
            store_id = ?
            AND ingredient_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'ingredient-001',
          ],
        );

        final Map<String, Object?> secondBalance = await _singleRow(
          database,
          table: 'ingredient_inventory',
          where: '''
            store_id = ?
            AND ingredient_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'ingredient-002',
          ],
        );

        expect(
          firstBalance['quantity'],
          4.5,
        );

        expect(
          secondBalance['quantity'],
          7,
        );

        final int movementCount = await _countRows(
          database,
          table: 'ingredient_movements',
        );

        expect(
          movementCount,
          2,
        );

        for (final PlannedInventoryMovement movement in plan.movements) {
          expect(
            await dao.hasProcessedMovement(
              database,
              movement,
            ),
            isTrue,
          );
        }
      },
    );

    test(
      'executes NONE Product plan without inventory writes',
      () async {
        final SaleConsumptionPlan plan = SaleConsumptionPlan(
          request: _request(),
          inventoryMode: ProductInventoryMode.none,
          movements: const <PlannedInventoryMovement>[],
          expectedCost: 0,
        );

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              plan,
            );
          },
        );

        expect(
          await _countRows(
            database,
            table: 'inventory_movements',
          ),
          0,
        );

        expect(
          await _countRows(
            database,
            table: 'ingredient_movements',
          ),
          0,
        );
      },
    );

    test(
      'rejects DIRECT consumption when balance is missing',
      () async {
        final SaleConsumptionPlan plan = _directPlan();

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await dao.executePlan(
                transaction,
                plan,
              );
            },
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Inventory balance was not found.',
            ),
          ),
        );

        expect(
          await _countRows(
            database,
            table: 'inventory_movements',
          ),
          0,
        );
      },
    );

    test(
      'rolls back RECIPE plan when one balance is missing',
      () async {
        await _insertIngredientBalance(
          database,
          id: 'ingredient-inventory-001',
          ingredientId: 'ingredient-001',
          quantity: 5,
          averageCost: 20,
        );

        final SaleConsumptionPlan plan = _recipePlan();

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await dao.executePlan(
                transaction,
                plan,
              );
            },
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Ingredient Inventory balance '
                  'was not found.',
            ),
          ),
        );

        final Map<String, Object?> balance = await _singleRow(
          database,
          table: 'ingredient_inventory',
          where: '''
            store_id = ?
            AND ingredient_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'ingredient-001',
          ],
        );

        expect(
          balance['quantity'],
          5,
        );

        expect(
          await _countRows(
            database,
            table: 'ingredient_movements',
          ),
          0,
        );
      },
    );

    test(
      'restores a DIRECT Product movement',
      () async {
        await _insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        final SaleConsumptionPlan consumption = _directPlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              consumption,
            );
          },
        );

        final String originalMovementId =
            consumption.movements.single.idempotencyKey.trim();

        final PlannedInventoryMovement restorationMovement =
            PlannedInventoryMovement(
          idempotencyKey: 'SALE:sale-001:sale-item-001:'
              'PRODUCT:product-001:restore',
          operation: ConsumptionOperation.restore,
          itemType: ConsumptionItemType.product,
          itemId: 'product-001',
          itemCode: 'SKU-001',
          unitCode: 'EACH',
          quantityDelta: 2,
          unitCostSnapshot: 50,
          sourceSaleId: 'sale-001',
          sourceSaleItemId: 'sale-item-001',
          storeId: 'store-001',
          performedBy: 'user-001',
          deviceId: 'device-001',
          occurredAt: DateTime.utc(
            2026,
            9,
            6,
          ),
          reversalOfMovementId: originalMovementId,
        );

        final SaleConsumptionPlan restorationPlan = SaleConsumptionPlan(
          request: _request(),
          inventoryMode: ProductInventoryMode.direct,
          movements: <PlannedInventoryMovement>[
            restorationMovement,
          ],
          expectedCost: 100,
        );

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              restorationPlan,
            );
          },
        );

        final Map<String, Object?> balance = await _singleRow(
          database,
          table: 'inventory',
          where: '''
            store_id = ?
            AND product_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'product-001',
          ],
        );

        expect(
          balance['quantity'],
          10,
        );

        final Map<String, Object?> restoration = await _singleRow(
          database,
          table: 'inventory_movements',
          where: 'idempotency_key = ?',
          whereArgs: const <Object?>[
            'SALE:sale-001:sale-item-001:'
                'PRODUCT:product-001:restore',
          ],
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
          restoration['movement_type'],
          'RESTORE',
        );
        expect(
          restoration['reversal_of_movement_id'],
          originalMovementId,
        );
      },
    );

    test(
      'rejects a second restoration of original movement',
      () async {
        await _insertProductBalance(
          database,
          quantity: 10,
          averageCost: 50,
        );

        final SaleConsumptionPlan consumption = _directPlan();

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              consumption,
            );
          },
        );

        final String originalMovementId =
            consumption.movements.single.idempotencyKey.trim();

        final SaleConsumptionPlan firstRestore = _restorationPlan(
          idempotencyKey: 'restore-product-001',
          originalMovementId: originalMovementId,
        );

        await database.transaction(
          (Transaction transaction) async {
            await dao.executePlan(
              transaction,
              firstRestore,
            );
          },
        );

        final SaleConsumptionPlan secondRestore = _restorationPlan(
          idempotencyKey: 'restore-product-002',
          originalMovementId: originalMovementId,
        );

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await dao.executePlan(
                transaction,
                secondRestore,
              );
            },
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) {
                return error.message;
              },
              'message',
              'Original movement was already '
                  'restored.',
            ),
          ),
        );

        final Map<String, Object?> balance = await _singleRow(
          database,
          table: 'inventory',
          where: '''
            store_id = ?
            AND product_id = ?
          ''',
          whereArgs: const <Object?>[
            'store-001',
            'product-001',
          ],
        );

        expect(
          balance['quantity'],
          10,
        );

        expect(
          await _countRows(
            database,
            table: 'inventory_movements',
          ),
          2,
        );
      },
    );
  });
}

SaleConsumptionRequest _request() {
  return SaleConsumptionRequest(
    saleId: 'sale-001',
    saleItemId: 'sale-item-001',
    storeId: 'store-001',
    productId: 'product-001',
    productSku: 'SKU-001',
    quantitySold: 2,
    occurredAt: DateTime.utc(
      2026,
      9,
      5,
    ),
    performedBy: 'user-001',
    deviceId: 'device-001',
  );
}

SaleConsumptionPlan _directPlan() {
  return SaleConsumptionPlan(
    request: _request(),
    inventoryMode: ProductInventoryMode.direct,
    movements: <PlannedInventoryMovement>[
      PlannedInventoryMovement(
        idempotencyKey: 'SALE:sale-001:sale-item-001:'
            'PRODUCT:product-001:consume',
        operation: ConsumptionOperation.consume,
        itemType: ConsumptionItemType.product,
        itemId: 'product-001',
        itemCode: 'SKU-001',
        unitCode: 'EACH',
        quantityDelta: -2,
        unitCostSnapshot: 50,
        sourceSaleId: 'sale-001',
        sourceSaleItemId: 'sale-item-001',
        storeId: 'store-001',
        performedBy: 'user-001',
        deviceId: 'device-001',
        occurredAt: DateTime.utc(
          2026,
          9,
          5,
        ),
      ),
    ],
    expectedCost: 100,
  );
}

SaleConsumptionPlan _recipePlan() {
  return SaleConsumptionPlan(
    request: _request(),
    inventoryMode: ProductInventoryMode.recipe,
    movements: <PlannedInventoryMovement>[
      PlannedInventoryMovement(
        idempotencyKey: 'SALE:sale-001:sale-item-001:'
            'INGREDIENT:ingredient-001',
        operation: ConsumptionOperation.consume,
        itemType: ConsumptionItemType.ingredient,
        itemId: 'ingredient-001',
        itemCode: 'ING-001',
        unitCode: 'KG',
        quantityDelta: -0.5,
        unitCostSnapshot: 20,
        sourceSaleId: 'sale-001',
        sourceSaleItemId: 'sale-item-001',
        storeId: 'store-001',
        performedBy: 'user-001',
        deviceId: 'device-001',
        occurredAt: DateTime.utc(
          2026,
          9,
          5,
        ),
        recipeId: 'recipe-001',
        recipeIngredientId: 'recipe-line-001',
      ),
      PlannedInventoryMovement(
        idempotencyKey: 'SALE:sale-001:sale-item-001:'
            'INGREDIENT:ingredient-002',
        operation: ConsumptionOperation.consume,
        itemType: ConsumptionItemType.ingredient,
        itemId: 'ingredient-002',
        itemCode: 'ING-002',
        unitCode: 'KG',
        quantityDelta: -1,
        unitCostSnapshot: 5,
        sourceSaleId: 'sale-001',
        sourceSaleItemId: 'sale-item-001',
        storeId: 'store-001',
        performedBy: 'user-001',
        deviceId: 'device-001',
        occurredAt: DateTime.utc(
          2026,
          9,
          5,
        ),
        recipeId: 'recipe-001',
        recipeIngredientId: 'recipe-line-002',
      ),
    ],
    expectedCost: 15,
  );
}

SaleConsumptionPlan _restorationPlan({
  required String idempotencyKey,
  required String originalMovementId,
}) {
  return SaleConsumptionPlan(
    request: _request(),
    inventoryMode: ProductInventoryMode.direct,
    movements: <PlannedInventoryMovement>[
      PlannedInventoryMovement(
        idempotencyKey: idempotencyKey,
        operation: ConsumptionOperation.restore,
        itemType: ConsumptionItemType.product,
        itemId: 'product-001',
        itemCode: 'SKU-001',
        unitCode: 'EACH',
        quantityDelta: 2,
        unitCostSnapshot: 50,
        sourceSaleId: 'sale-001',
        sourceSaleItemId: 'sale-item-001',
        storeId: 'store-001',
        performedBy: 'user-001',
        deviceId: 'device-001',
        occurredAt: DateTime.utc(
          2026,
          9,
          6,
        ),
        reversalOfMovementId: originalMovementId,
      ),
    ],
    expectedCost: 100,
  );
}

Future<void> _createVersion8InventorySchema(
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
    CREATE INDEX
      idx_ingredient_movements_reference
    ON ingredient_movements(reference_id)
    ''',
  );
}

Future<void> _insertProductBalance(
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

Future<void> _insertIngredientBalance(
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

Future<Map<String, Object?>> _singleRow(
  Database database, {
  required String table,
  required String where,
  required List<Object?> whereArgs,
}) async {
  final List<Map<String, Object?>> rows = await database.query(
    table,
    where: where,
    whereArgs: whereArgs,
    limit: 1,
  );

  expect(
    rows,
    hasLength(1),
  );

  return rows.single;
}

Future<int> _countRows(
  Database database, {
  required String table,
}) async {
  final List<Map<String, Object?>> rows = await database.rawQuery(
    'SELECT COUNT(*) AS row_count FROM $table',
  );

  return rows.single['row_count']! as int;
}
