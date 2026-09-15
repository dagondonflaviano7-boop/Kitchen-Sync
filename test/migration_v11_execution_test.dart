import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v11.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );

    await database.execute(
      'PRAGMA foreign_keys = ON',
    );

    await _createVersion10Schema(database);
    await _insertVersion10Records(database);
    await _applyMigrationV11(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Migration V11 Sale Restoration SQLite execution', () {
    test('creates Restoration tables', () async {
      expect(
        await _tableExists(
          database,
          'sale_restorations',
        ),
        isTrue,
      );

      expect(
        await _tableExists(
          database,
          'sale_restoration_items',
        ),
        isTrue,
      );
    });

    test('creates required Restoration header columns', () async {
      final Set<String> columns = await _columnNames(
        database,
        'sale_restorations',
      );

      expect(
        columns,
        containsAll(<String>[
          'id',
          'restoration_transaction_number',
          'original_sale_id',
          'operation',
          'reason',
          'subtotal',
          'discount',
          'net_sales',
          'cost',
          'cogs',
          'gross_profit',
          'gross_margin',
          'performed_by',
          'device_id',
          'occurred_at',
          'sync_status',
        ]),
      );
    });

    test('creates required Restoration Item columns', () async {
      final Set<String> columns = await _columnNames(
        database,
        'sale_restoration_items',
      );

      expect(
        columns,
        containsAll(<String>[
          'id',
          'restoration_id',
          'original_sale_item_id',
          'product_id',
          'sku',
          'product_name',
          'quantity',
          'selling_price',
          'discount',
          'net_amount',
          'unit_cost',
          'cogs',
          'recipe_version',
          'ingredient_cost_json',
        ]),
      );
    });

    test('adds Restoration ownership to movement ledgers', () async {
      final Set<String> productColumns = await _columnNames(
        database,
        'inventory_movements',
      );

      final Set<String> ingredientColumns = await _columnNames(
        database,
        'ingredient_movements',
      );

      expect(
        productColumns,
        contains('source_restoration_id'),
      );

      expect(
        ingredientColumns,
        contains('source_restoration_id'),
      );
    });

    test('creates Restoration lookup indexes', () async {
      final Set<String> headerIndexes = await _indexNames(
        database,
        'sale_restorations',
      );

      final Set<String> itemIndexes = await _indexNames(
        database,
        'sale_restoration_items',
      );

      expect(
        headerIndexes,
        containsAll(<String>[
          'idx_sale_restorations_original_sale',
          'idx_sale_restorations_sync',
        ]),
      );

      expect(
        itemIndexes,
        containsAll(<String>[
          'idx_sale_restoration_items_restoration',
          'idx_sale_restoration_items_original_item',
        ]),
      );
    });

    test('creates movement Restoration indexes', () async {
      final Set<String> productIndexes = await _indexNames(
        database,
        'inventory_movements',
      );

      final Set<String> ingredientIndexes = await _indexNames(
        database,
        'ingredient_movements',
      );

      expect(
        productIndexes,
        containsAll(<String>[
          'idx_inventory_movements_restoration',
          'idx_inventory_movements_one_reversal',
        ]),
      );

      expect(
        ingredientIndexes,
        containsAll(<String>[
          'idx_ingredient_movements_restoration',
          'idx_ingredient_movements_one_reversal',
        ]),
      );
    });

    test('preserves Version 10 Sale records', () async {
      final Map<String, Object?> sale = (await database.query(
        'sales',
        where: 'id = ?',
        whereArgs: const <Object?>[
          'sale-legacy-001',
        ],
      ))
          .single;

      final Map<String, Object?> saleItem = (await database.query(
        'sale_items',
        where: 'id = ?',
        whereArgs: const <Object?>[
          'sale-item-legacy-001',
        ],
      ))
          .single;

      expect(sale['transaction_number'], 'TXN-LEGACY-001');
      expect(sale['cogs'], 50.0);
      expect(saleItem['unit_cost'], 25.0);
      expect(saleItem['cogs'], 50.0);
    });

    test('preserves Version 10 movement records', () async {
      final Map<String, Object?> productMovement = (await database.query(
        'inventory_movements',
        where: 'id = ?',
        whereArgs: const <Object?>[
          'product-movement-legacy-001',
        ],
      ))
          .single;

      final Map<String, Object?> ingredientMovement = (await database.query(
        'ingredient_movements',
        where: 'id = ?',
        whereArgs: const <Object?>[
          'ingredient-movement-legacy-001',
        ],
      ))
          .single;

      expect(productMovement['quantity'], -2.0);
      expect(productMovement['source_restoration_id'], isNull);

      expect(ingredientMovement['quantity'], -100.0);
      expect(ingredientMovement['source_restoration_id'], isNull);
    });

    test('passes foreign-key integrity check', () async {
      final List<Map<String, Object?>> violations = await database.rawQuery(
        'PRAGMA foreign_key_check',
      );

      expect(violations, isEmpty);
    });
  });
}

Future<void> _applyMigrationV11(
  Database database,
) async {
  for (final String statement in migrationV11) {
    await database.execute(statement);
  }
}

Future<bool> _tableExists(
  Database database,
  String table,
) async {
  final List<Map<String, Object?>> rows = await database.rawQuery(
    '''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name = ?
    ''',
    <Object?>[table],
  );

  return rows.isNotEmpty;
}

Future<Set<String>> _columnNames(
  Database database,
  String table,
) async {
  final List<Map<String, Object?>> rows = await database.rawQuery(
    'PRAGMA table_info($table)',
  );

  return rows
      .map(
        (Map<String, Object?> row) => row['name']! as String,
      )
      .toSet();
}

Future<Set<String>> _indexNames(
  Database database,
  String table,
) async {
  final List<Map<String, Object?>> rows = await database.rawQuery(
    'PRAGMA index_list($table)',
  );

  return rows
      .map(
        (Map<String, Object?> row) => row['name']! as String,
      )
      .toSet();
}

Future<void> _createVersion10Schema(
  Database database,
) async {
  await database.execute(
    '''
    CREATE TABLE sales (
      id TEXT PRIMARY KEY,
      transaction_number TEXT NOT NULL,
      cogs REAL NOT NULL
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE sale_items (
      id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      unit_cost REAL NOT NULL,
      cogs REAL NOT NULL,
      FOREIGN KEY(transaction_id) REFERENCES sales(id)
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE inventory_movements (
      id TEXT PRIMARY KEY,
      quantity REAL NOT NULL,
      reversal_of_movement_id TEXT
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE ingredient_movements (
      id TEXT PRIMARY KEY,
      quantity REAL NOT NULL,
      reversal_of_movement_id TEXT
    )
    ''',
  );
}

Future<void> _insertVersion10Records(
  Database database,
) async {
  await database.insert(
    'sales',
    const <String, Object?>{
      'id': 'sale-legacy-001',
      'transaction_number': 'TXN-LEGACY-001',
      'cogs': 50.0,
    },
  );

  await database.insert(
    'sale_items',
    const <String, Object?>{
      'id': 'sale-item-legacy-001',
      'transaction_id': 'sale-legacy-001',
      'unit_cost': 25.0,
      'cogs': 50.0,
    },
  );

  await database.insert(
    'inventory_movements',
    const <String, Object?>{
      'id': 'product-movement-legacy-001',
      'quantity': -2.0,
      'reversal_of_movement_id': null,
    },
  );

  await database.insert(
    'ingredient_movements',
    const <String, Object?>{
      'id': 'ingredient-movement-legacy-001',
      'quantity': -100.0,
      'reversal_of_movement_id': null,
    },
  );
}
