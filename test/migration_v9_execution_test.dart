import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v9.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

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
        await _createVersion8Schema(db);
      },
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Movement Audit Migration V9 execution', () {
    test(
      'applies all statements and preserves legacy movements',
      () async {
        await _insertLegacyProductMovement(database);
        await _insertLegacyIngredientMovement(database);

        await _applyMigrationV9(database);

        final Map<String, Object?> productMovement = (await database.query(
          'inventory_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'legacy-product-movement',
          ],
        ))
            .single;

        expect(
          productMovement['store_id'],
          'store-001',
        );
        expect(
          productMovement['item_id'],
          'product-001',
        );
        expect(
          productMovement['quantity'],
          -2,
        );
        expect(
          productMovement['before_quantity'],
          10,
        );
        expect(
          productMovement['after_quantity'],
          8,
        );
        expect(
          productMovement['movement_type'],
          'SALE',
        );
        expect(
          productMovement['reference_id'],
          'sale-legacy-001',
        );
        expect(
          productMovement['user_id'],
          'user-001',
        );
        expect(
          productMovement['device_id'],
          'device-001',
        );
        expect(
          productMovement['remarks'],
          'Legacy Product movement',
        );

        expect(
          productMovement['idempotency_key'],
          isNull,
        );
        expect(
          productMovement['source_sale_id'],
          isNull,
        );
        expect(
          productMovement['source_sale_item_id'],
          isNull,
        );
        expect(
          productMovement['reversal_of_movement_id'],
          isNull,
        );
        expect(
          productMovement['unit_cost_snapshot'],
          0,
        );

        final Map<String, Object?> ingredientMovement = (await database.query(
          'ingredient_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'legacy-ingredient-movement',
          ],
        ))
            .single;

        expect(
          ingredientMovement['store_id'],
          'store-001',
        );
        expect(
          ingredientMovement['item_id'],
          'ingredient-001',
        );
        expect(
          ingredientMovement['quantity'],
          -0.5,
        );
        expect(
          ingredientMovement['before_quantity'],
          5,
        );
        expect(
          ingredientMovement['after_quantity'],
          4.5,
        );
        expect(
          ingredientMovement['movement_type'],
          'SALE',
        );
        expect(
          ingredientMovement['reference_id'],
          'sale-legacy-001',
        );
        expect(
          ingredientMovement['remarks'],
          'Legacy Ingredient movement',
        );

        expect(
          ingredientMovement['idempotency_key'],
          isNull,
        );
        expect(
          ingredientMovement['source_sale_id'],
          isNull,
        );
        expect(
          ingredientMovement['source_sale_item_id'],
          isNull,
        );
        expect(
          ingredientMovement['reversal_of_movement_id'],
          isNull,
        );
        expect(
          ingredientMovement['unit_cost_snapshot'],
          0,
        );
      },
    );

    test(
      'creates Product and Ingredient movement audit columns',
      () async {
        await _applyMigrationV9(database);

        final Set<Object?> productColumns = (await database.rawQuery(
          'PRAGMA table_info(inventory_movements)',
        ))
            .map(
          (Map<String, Object?> column) {
            return column['name'];
          },
        ).toSet();

        final Set<Object?> ingredientColumns = (await database.rawQuery(
          'PRAGMA table_info(ingredient_movements)',
        ))
            .map(
          (Map<String, Object?> column) {
            return column['name'];
          },
        ).toSet();

        const Set<String> expectedColumns = <String>{
          'idempotency_key',
          'source_sale_id',
          'source_sale_item_id',
          'reversal_of_movement_id',
          'unit_cost_snapshot',
        };

        expect(
          productColumns,
          containsAll(expectedColumns),
        );

        expect(
          ingredientColumns,
          containsAll(expectedColumns),
        );
      },
    );

    test(
      'creates idempotency and reversal indexes',
      () async {
        await _applyMigrationV9(database);

        final Set<Object?> productIndexes = (await database.rawQuery(
          'PRAGMA index_list(inventory_movements)',
        ))
            .map(
          (Map<String, Object?> index) {
            return index['name'];
          },
        ).toSet();

        final Set<Object?> ingredientIndexes = (await database.rawQuery(
          'PRAGMA index_list(ingredient_movements)',
        ))
            .map(
          (Map<String, Object?> index) {
            return index['name'];
          },
        ).toSet();

        expect(
          productIndexes,
          containsAll(
            const <String>{
              'idx_movements_reference',
              'idx_inventory_movements_idempotency',
              'idx_inventory_movements_reversal',
            },
          ),
        );

        expect(
          ingredientIndexes,
          containsAll(
            const <String>{
              'idx_ingredient_movements_reference',
              'idx_ingredient_movements_idempotency',
              'idx_ingredient_movements_reversal',
            },
          ),
        );
      },
    );

    test(
      'stores complete Product movement Sale lineage',
      () async {
        await _applyMigrationV9(database);

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'product-movement-001',
            idempotencyKey: 'SALE:sale-001:'
                'sale-item-001:PRODUCT:'
                'product-001:consume',
            sourceSaleId: 'sale-001',
            sourceSaleItemId: 'sale-item-001',
            unitCostSnapshot: 50,
          ),
        );

        final Map<String, Object?> row = (await database.query(
          'inventory_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'product-movement-001',
          ],
        ))
            .single;

        expect(
          row['idempotency_key'],
          'SALE:sale-001:sale-item-001:'
          'PRODUCT:product-001:consume',
        );
        expect(
          row['source_sale_id'],
          'sale-001',
        );
        expect(
          row['source_sale_item_id'],
          'sale-item-001',
        );
        expect(
          row['unit_cost_snapshot'],
          50,
        );
      },
    );

    test(
      'stores complete Ingredient movement Sale lineage',
      () async {
        await _applyMigrationV9(database);

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'ingredient-movement-001',
            idempotencyKey: 'SALE:sale-001:'
                'sale-item-001:INGREDIENT:'
                'ingredient-001',
            sourceSaleId: 'sale-001',
            sourceSaleItemId: 'sale-item-001',
            unitCostSnapshot: 20,
          ),
        );

        final Map<String, Object?> row = (await database.query(
          'ingredient_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'ingredient-movement-001',
          ],
        ))
            .single;

        expect(
          row['idempotency_key'],
          'SALE:sale-001:sale-item-001:'
          'INGREDIENT:ingredient-001',
        );
        expect(
          row['source_sale_id'],
          'sale-001',
        );
        expect(
          row['source_sale_item_id'],
          'sale-item-001',
        );
        expect(
          row['unit_cost_snapshot'],
          20,
        );
      },
    );

    test(
      'rejects duplicate Product movement idempotency keys',
      () async {
        await _applyMigrationV9(database);

        const String key = 'SALE:sale-001:'
            'sale-item-001:PRODUCT:'
            'product-001:consume';

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'product-movement-001',
            idempotencyKey: key,
          ),
        );

        await expectLater(
          database.insert(
            'inventory_movements',
            _productMovementValues(
              id: 'product-movement-002',
              idempotencyKey: key,
            ),
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );
      },
    );

    test(
      'rejects duplicate Ingredient movement idempotency keys',
      () async {
        await _applyMigrationV9(database);

        const String key = 'SALE:sale-001:'
            'sale-item-001:INGREDIENT:'
            'ingredient-001';

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'ingredient-movement-001',
            idempotencyKey: key,
          ),
        );

        await expectLater(
          database.insert(
            'ingredient_movements',
            _ingredientMovementValues(
              id: 'ingredient-movement-002',
              idempotencyKey: key,
            ),
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );
      },
    );

    test(
      'allows multiple legacy rows with null idempotency keys',
      () async {
        await _applyMigrationV9(database);

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'legacy-product-null-001',
          ),
        );

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'legacy-product-null-002',
          ),
        );

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'legacy-ingredient-null-001',
          ),
        );

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'legacy-ingredient-null-002',
          ),
        );

        final int productCount = Sqflite.firstIntValue(
              await database.rawQuery(
                '''
                    SELECT COUNT(*)
                    FROM inventory_movements
                    WHERE idempotency_key IS NULL
                    ''',
              ),
            ) ??
            0;

        final int ingredientCount = Sqflite.firstIntValue(
              await database.rawQuery(
                '''
                    SELECT COUNT(*)
                    FROM ingredient_movements
                    WHERE idempotency_key IS NULL
                    ''',
              ),
            ) ??
            0;

        expect(
          productCount,
          2,
        );
        expect(
          ingredientCount,
          2,
        );
      },
    );

    test(
      'rejects negative Product movement unit cost',
      () async {
        await _applyMigrationV9(database);

        await expectLater(
          database.insert(
            'inventory_movements',
            _productMovementValues(
              id: 'negative-product-cost',
              idempotencyKey: 'negative-product-cost-key',
              unitCostSnapshot: -1,
            ),
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );
      },
    );

    test(
      'rejects negative Ingredient movement unit cost',
      () async {
        await _applyMigrationV9(database);

        await expectLater(
          database.insert(
            'ingredient_movements',
            _ingredientMovementValues(
              id: 'negative-ingredient-cost',
              idempotencyKey: 'negative-ingredient-cost-key',
              unitCostSnapshot: -1,
            ),
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );
      },
    );

    test(
      'accepts zero movement unit costs',
      () async {
        await _applyMigrationV9(database);

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'zero-product-cost',
            idempotencyKey: 'zero-product-cost-key',
            unitCostSnapshot: 0,
          ),
        );

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'zero-ingredient-cost',
            idempotencyKey: 'zero-ingredient-cost-key',
            unitCostSnapshot: 0,
          ),
        );

        final Map<String, Object?> productRow = (await database.query(
          'inventory_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'zero-product-cost',
          ],
        ))
            .single;

        final Map<String, Object?> ingredientRow = (await database.query(
          'ingredient_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'zero-ingredient-cost',
          ],
        ))
            .single;

        expect(
          productRow['unit_cost_snapshot'],
          0,
        );
        expect(
          ingredientRow['unit_cost_snapshot'],
          0,
        );
      },
    );

    test(
      'stores Product and Ingredient restoration links',
      () async {
        await _applyMigrationV9(database);

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'product-consumption-001',
            idempotencyKey: 'product-consumption-key',
          ),
        );

        await database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'product-restoration-001',
            idempotencyKey: 'product-restoration-key',
            quantity: 2,
            beforeQuantity: 8,
            afterQuantity: 10,
            movementType: 'RESTORE',
            reversalOfMovementId: 'product-consumption-001',
          ),
        );

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'ingredient-consumption-001',
            idempotencyKey: 'ingredient-consumption-key',
          ),
        );

        await database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'ingredient-restoration-001',
            idempotencyKey: 'ingredient-restoration-key',
            quantity: 0.5,
            beforeQuantity: 4.5,
            afterQuantity: 5,
            movementType: 'RESTORE',
            reversalOfMovementId: 'ingredient-consumption-001',
          ),
        );

        final Map<String, Object?> productRestoration = (await database.query(
          'inventory_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'product-restoration-001',
          ],
        ))
            .single;

        final Map<String, Object?> ingredientRestoration =
            (await database.query(
          'ingredient_movements',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'ingredient-restoration-001',
          ],
        ))
                .single;

        expect(
          productRestoration['reversal_of_movement_id'],
          'product-consumption-001',
        );

        expect(
          ingredientRestoration['reversal_of_movement_id'],
          'ingredient-consumption-001',
        );
      },
    );

    test(
      'does not modify Product or Ingredient balances',
      () async {
        await database.insert(
          'inventory',
          const <String, Object?>{
            'id': 'inventory-001',
            'store_id': 'store-001',
            'product_id': 'product-001',
            'quantity': 10,
            'average_cost': 50,
            'updated_at': '2026-09-05T00:00:00.000Z',
          },
        );

        await database.insert(
          'ingredient_inventory',
          const <String, Object?>{
            'id': 'ingredient-inventory-001',
            'store_id': 'store-001',
            'ingredient_id': 'ingredient-001',
            'quantity': 5,
            'average_cost': 20,
            'updated_at': '2026-09-05T00:00:00.000Z',
          },
        );

        await _applyMigrationV9(database);

        final Map<String, Object?> productBalance = (await database.query(
          'inventory',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'inventory-001',
          ],
        ))
            .single;

        final Map<String, Object?> ingredientBalance = (await database.query(
          'ingredient_inventory',
          where: 'id = ?',
          whereArgs: const <Object?>[
            'ingredient-inventory-001',
          ],
        ))
            .single;

        expect(
          productBalance['quantity'],
          10,
        );
        expect(
          productBalance['average_cost'],
          50,
        );

        expect(
          ingredientBalance['quantity'],
          5,
        );
        expect(
          ingredientBalance['average_cost'],
          20,
        );
      },
    );
  });
}

Future<void> _createVersion8Schema(
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

Future<void> _applyMigrationV9(
  Database database,
) async {
  for (final String statement in migrationV9) {
    await database.execute(statement);
  }
}

Future<void> _insertLegacyProductMovement(
  Database database,
) async {
  await database.insert(
    'inventory_movements',
    const <String, Object?>{
      'id': 'legacy-product-movement',
      'store_id': 'store-001',
      'item_id': 'product-001',
      'quantity': -2,
      'before_quantity': 10,
      'after_quantity': 8,
      'movement_type': 'SALE',
      'reference_id': 'sale-legacy-001',
      'user_id': 'user-001',
      'device_id': 'device-001',
      'created_at': '2026-09-05T00:00:00.000Z',
      'remarks': 'Legacy Product movement',
    },
  );
}

Future<void> _insertLegacyIngredientMovement(
  Database database,
) async {
  await database.insert(
    'ingredient_movements',
    const <String, Object?>{
      'id': 'legacy-ingredient-movement',
      'store_id': 'store-001',
      'item_id': 'ingredient-001',
      'quantity': -0.5,
      'before_quantity': 5,
      'after_quantity': 4.5,
      'movement_type': 'SALE',
      'reference_id': 'sale-legacy-001',
      'user_id': 'user-001',
      'device_id': 'device-001',
      'created_at': '2026-09-05T00:00:00.000Z',
      'remarks': 'Legacy Ingredient movement',
    },
  );
}

Map<String, Object?> _productMovementValues({
  required String id,
  String? idempotencyKey,
  String? sourceSaleId,
  String? sourceSaleItemId,
  String? reversalOfMovementId,
  double quantity = -2,
  double beforeQuantity = 10,
  double afterQuantity = 8,
  double unitCostSnapshot = 50,
  String movementType = 'SALE',
}) {
  return <String, Object?>{
    'id': id,
    'store_id': 'store-001',
    'item_id': 'product-001',
    'quantity': quantity,
    'before_quantity': beforeQuantity,
    'after_quantity': afterQuantity,
    'movement_type': movementType,
    'reference_id': 'sale-001',
    'user_id': 'user-001',
    'device_id': 'device-001',
    'created_at': '2026-09-05T00:00:00.000Z',
    'remarks': 'Product Sale Consumption movement',
    'idempotency_key': idempotencyKey,
    'source_sale_id': sourceSaleId,
    'source_sale_item_id': sourceSaleItemId,
    'reversal_of_movement_id': reversalOfMovementId,
    'unit_cost_snapshot': unitCostSnapshot,
  };
}

Map<String, Object?> _ingredientMovementValues({
  required String id,
  String? idempotencyKey,
  String? sourceSaleId,
  String? sourceSaleItemId,
  String? reversalOfMovementId,
  double quantity = -0.5,
  double beforeQuantity = 5,
  double afterQuantity = 4.5,
  double unitCostSnapshot = 20,
  String movementType = 'SALE',
}) {
  return <String, Object?>{
    'id': id,
    'store_id': 'store-001',
    'item_id': 'ingredient-001',
    'quantity': quantity,
    'before_quantity': beforeQuantity,
    'after_quantity': afterQuantity,
    'movement_type': movementType,
    'reference_id': 'sale-001',
    'user_id': 'user-001',
    'device_id': 'device-001',
    'created_at': '2026-09-05T00:00:00.000Z',
    'remarks': 'Ingredient Sale Consumption movement',
    'idempotency_key': idempotencyKey,
    'source_sale_id': sourceSaleId,
    'source_sale_item_id': sourceSaleItemId,
    'reversal_of_movement_id': reversalOfMovementId,
    'unit_cost_snapshot': unitCostSnapshot,
  };
}
