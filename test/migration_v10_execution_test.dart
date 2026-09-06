import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v10.dart';
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
        await _createVersion9Schema(
          db,
        );
      },
    );
  });

  tearDown(() async {
    await database.close();
  });

  group(
    'Ingredient Movement Recipe Lineage '
    'Migration V10 execution',
    () {
      test(
        'applies all V10 statements',
        () async {
          await _applyMigrationV10(
            database,
          );

          final Set<Object?> ingredientMovementColumns =
              (await database.rawQuery(
            '''
            PRAGMA table_info(
              ingredient_movements
            )
            ''',
          ))
                  .map(
            (
              Map<String, Object?> column,
            ) {
              return column['name'];
            },
          ).toSet();

          expect(
            ingredientMovementColumns,
            containsAll(
              const <String>{
                'recipe_id',
                'recipe_ingredient_id',
              },
            ),
          );
        },
      );

      test(
        'preserves existing Ingredient movement',
        () async {
          await _insertLegacyMovement(
            database,
          );

          await _applyMigrationV10(
            database,
          );

          final Map<String, Object?> row = (await database.query(
            'ingredient_movements',
            where: 'id = ?',
            whereArgs: const <Object?>[
              'legacy-movement-001',
            ],
          ))
              .single;

          expect(
            row['id'],
            'legacy-movement-001',
          );

          expect(
            row['store_id'],
            'store-001',
          );

          expect(
            row['item_id'],
            'ingredient-001',
          );

          expect(
            row['quantity'],
            -0.5,
          );

          expect(
            row['before_quantity'],
            5,
          );

          expect(
            row['after_quantity'],
            4.5,
          );

          expect(
            row['movement_type'],
            'CONSUME',
          );

          expect(
            row['reference_id'],
            'sale-001',
          );

          expect(
            row['idempotency_key'],
            'legacy-key-001',
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

          expect(
            row['recipe_id'],
            isNull,
          );

          expect(
            row['recipe_ingredient_id'],
            isNull,
          );
        },
      );

      test(
        'creates Recipe lineage indexes',
        () async {
          await _applyMigrationV10(
            database,
          );

          final List<Map<String, Object?>> indexes = await database.rawQuery(
            '''
            PRAGMA index_list(
              ingredient_movements
            )
            ''',
          );

          final Set<Object?> indexNames = indexes.map(
            (
              Map<String, Object?> index,
            ) {
              return index['name'];
            },
          ).toSet();

          expect(
            indexNames,
            contains(
              'idx_ingredient_movements_recipe',
            ),
          );

          expect(
            indexNames,
            contains(
              'idx_ingredient_movements_recipe_line',
            ),
          );

          expect(
            indexNames,
            contains(
              'idx_ingredient_movements_idempotency',
            ),
          );

          expect(
            indexNames,
            contains(
              'idx_ingredient_movements_reversal',
            ),
          );

          expect(
            indexNames,
            contains(
              'idx_ingredient_movements_reference',
            ),
          );
        },
      );

      test(
        'stores Ingredient movement Recipe lineage',
        () async {
          await _applyMigrationV10(
            database,
          );

          await database.insert(
            'ingredient_movements',
            _movementValues(
              id: 'recipe-movement-001',
              idempotencyKey: 'SALE:sale-001:'
                  'sale-item-001:'
                  'INGREDIENT:ingredient-001',
              recipeId: 'recipe-001',
              recipeIngredientId: 'recipe-line-001',
            ),
          );

          final Map<String, Object?> row = (await database.query(
            'ingredient_movements',
            where: 'id = ?',
            whereArgs: const <Object?>[
              'recipe-movement-001',
            ],
          ))
              .single;

          expect(
            row['recipe_id'],
            'recipe-001',
          );

          expect(
            row['recipe_ingredient_id'],
            'recipe-line-001',
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
        'allows null Recipe lineage',
        () async {
          await _applyMigrationV10(
            database,
          );

          await database.insert(
            'ingredient_movements',
            _movementValues(
              id: 'movement-without-recipe',
              idempotencyKey: 'movement-without-recipe-key',
            ),
          );

          final Map<String, Object?> row = (await database.query(
            'ingredient_movements',
            where: 'id = ?',
            whereArgs: const <Object?>[
              'movement-without-recipe',
            ],
          ))
              .single;

          expect(
            row['recipe_id'],
            isNull,
          );

          expect(
            row['recipe_ingredient_id'],
            isNull,
          );
        },
      );

      test(
        'queries movements by Recipe ID',
        () async {
          await _applyMigrationV10(
            database,
          );

          await database.insert(
            'ingredient_movements',
            _movementValues(
              id: 'recipe-movement-001',
              idempotencyKey: 'recipe-movement-key-001',
              recipeId: 'recipe-001',
              recipeIngredientId: 'recipe-line-001',
            ),
          );

          await database.insert(
            'ingredient_movements',
            _movementValues(
              id: 'recipe-movement-002',
              idempotencyKey: 'recipe-movement-key-002',
              recipeId: 'recipe-002',
              recipeIngredientId: 'recipe-line-002',
            ),
          );

          final List<Map<String, Object?>> recipeRows = await database.query(
            'ingredient_movements',
            where: 'recipe_id = ?',
            whereArgs: const <Object?>[
              'recipe-001',
            ],
          );

          expect(
            recipeRows,
            hasLength(1),
          );

          expect(
            recipeRows.single['id'],
            'recipe-movement-001',
          );

          expect(
            recipeRows.single['recipe_ingredient_id'],
            'recipe-line-001',
          );
        },
      );

      test(
        'queries movement by Recipe line ID',
        () async {
          await _applyMigrationV10(
            database,
          );

          await database.insert(
            'ingredient_movements',
            _movementValues(
              id: 'recipe-line-movement-001',
              idempotencyKey: 'recipe-line-key-001',
              recipeId: 'recipe-001',
              recipeIngredientId: 'recipe-line-001',
            ),
          );

          final List<Map<String, Object?>> rows = await database.query(
            'ingredient_movements',
            where: 'recipe_ingredient_id = ?',
            whereArgs: const <Object?>[
              'recipe-line-001',
            ],
          );

          expect(
            rows,
            hasLength(1),
          );

          expect(
            rows.single['recipe_id'],
            'recipe-001',
          );
        },
      );

      test(
        'does not modify Ingredient balance',
        () async {
          await database.insert(
            'ingredient_inventory',
            const <String, Object?>{
              'id': 'ingredient-inventory-001',
              'store_id': 'store-001',
              'ingredient_id': 'ingredient-001',
              'quantity': 5,
              'average_cost': 20,
              'updated_at': '2026-09-06T00:00:00.000Z',
            },
          );

          await _applyMigrationV10(
            database,
          );

          final Map<String, Object?> balance = (await database.query(
            'ingredient_inventory',
            where: 'id = ?',
            whereArgs: const <Object?>[
              'ingredient-inventory-001',
            ],
          ))
              .single;

          expect(
            balance['quantity'],
            5,
          );

          expect(
            balance['average_cost'],
            20,
          );

          expect(
            balance['updated_at'],
            '2026-09-06T00:00:00.000Z',
          );
        },
      );

      test(
        'preserves V9 idempotency constraint',
        () async {
          await _applyMigrationV10(
            database,
          );

          const String duplicateKey = 'duplicate-recipe-movement-key';

          await database.insert(
            'ingredient_movements',
            _movementValues(
              id: 'duplicate-movement-001',
              idempotencyKey: duplicateKey,
              recipeId: 'recipe-001',
              recipeIngredientId: 'recipe-line-001',
            ),
          );

          await expectLater(
            database.insert(
              'ingredient_movements',
              _movementValues(
                id: 'duplicate-movement-002',
                idempotencyKey: duplicateKey,
                recipeId: 'recipe-001',
                recipeIngredientId: 'recipe-line-001',
              ),
            ),
            throwsA(
              isA<DatabaseException>(),
            ),
          );
        },
      );
    },
  );
}

Future<void> _createVersion9Schema(
  Database db,
) async {
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
      remarks TEXT,
      idempotency_key TEXT,
      source_sale_id TEXT,
      source_sale_item_id TEXT,
      reversal_of_movement_id TEXT,
      unit_cost_snapshot REAL NOT NULL
        DEFAULT 0
        CHECK(unit_cost_snapshot >= 0)
    )
    ''',
  );

  await db.execute(
    '''
    CREATE INDEX
      idx_ingredient_movements_reference
    ON ingredient_movements(reference_id)
    ''',
  );

  await db.execute(
    '''
    CREATE UNIQUE INDEX
      idx_ingredient_movements_idempotency
    ON ingredient_movements(idempotency_key)
    WHERE idempotency_key IS NOT NULL
    ''',
  );

  await db.execute(
    '''
    CREATE INDEX
      idx_ingredient_movements_reversal
    ON ingredient_movements(
      reversal_of_movement_id
    )
    ''',
  );
}

Future<void> _applyMigrationV10(
  Database database,
) async {
  for (final String statement in migrationV10) {
    await database.execute(
      statement,
    );
  }
}

Future<void> _insertLegacyMovement(
  Database database,
) async {
  await database.insert(
    'ingredient_movements',
    _movementValues(
      id: 'legacy-movement-001',
      idempotencyKey: 'legacy-key-001',
    ),
  );
}

Map<String, Object?> _movementValues({
  required String id,
  required String idempotencyKey,
  String? recipeId,
  String? recipeIngredientId,
}) {
  return <String, Object?>{
    'id': id,
    'store_id': 'store-001',
    'item_id': 'ingredient-001',
    'quantity': -0.5,
    'before_quantity': 5,
    'after_quantity': 4.5,
    'movement_type': 'CONSUME',
    'reference_id': 'sale-001',
    'user_id': 'user-001',
    'device_id': 'device-001',
    'created_at': '2026-09-06T00:00:00.000Z',
    'remarks': 'Ingredient Sale Consumption movement',
    'idempotency_key': idempotencyKey,
    'source_sale_id': 'sale-001',
    'source_sale_item_id': 'sale-item-001',
    'reversal_of_movement_id': null,
    'unit_cost_snapshot': 20,
    if (recipeId != null) 'recipe_id': recipeId,
    if (recipeIngredientId != null) 'recipe_ingredient_id': recipeIngredientId,
  };
}
