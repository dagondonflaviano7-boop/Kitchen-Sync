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
    await _insertOriginalSale(database);
    await _applyMigrationV11(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Migration V11 Restoration constraints', () {
    test('inserts valid VOID header and Item', () async {
      await database.insert(
        'sale_restorations',
        _restorationValues(),
      );

      await database.insert(
        'sale_restoration_items',
        _restorationItemValues(),
      );

      final Map<String, Object?> restoration = (await database.query(
        'sale_restorations',
      ))
          .single;

      final Map<String, Object?> restorationItem = (await database.query(
        'sale_restoration_items',
      ))
          .single;

      expect(
        restoration['operation'],
        'VOID',
      );

      expect(
        restoration['original_sale_id'],
        'sale-001',
      );

      expect(
        restoration['net_sales'],
        -180.0,
      );

      expect(
        restoration['cogs'],
        -50.0,
      );

      expect(
        restorationItem['original_sale_item_id'],
        'sale-item-001',
      );

      expect(
        restorationItem['unit_cost'],
        25.0,
      );

      expect(
        restorationItem['cogs'],
        50.0,
      );
    });

    test('accepts supported REFUND operation', () async {
      await database.insert(
        'sale_restorations',
        _restorationValues(
          id: 'restoration-refund-001',
          transactionNumber: 'REFUND-0001',
          operation: 'REFUND',
        ),
      );

      final Map<String, Object?> restoration = (await database.query(
        'sale_restorations',
      ))
          .single;

      expect(
        restoration['operation'],
        'REFUND',
      );
    });

    test('rejects unsupported operation', () async {
      await expectLater(
        database.insert(
          'sale_restorations',
          _restorationValues(
            operation: 'CANCEL',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      expect(
        await _tableCount(
          database,
          'sale_restorations',
        ),
        0,
      );
    });

    test('rejects positive financial reversals', () async {
      for (final String column in <String>[
        'subtotal',
        'discount',
        'net_sales',
        'cost',
        'cogs',
      ]) {
        final Map<String, Object?> values = _restorationValues(
          id: 'restoration-positive-$column',
          transactionNumber: 'RESTORE-$column',
        );

        values[column] = 1.0;

        await expectLater(
          database.insert(
            'sale_restorations',
            values,
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
          reason: '$column must reject a positive value.',
        );
      }

      expect(
        await _tableCount(
          database,
          'sale_restorations',
        ),
        0,
      );
    });

    test('rejects duplicate transaction number', () async {
      await database.insert(
        'sale_restorations',
        _restorationValues(),
      );

      await expectLater(
        database.insert(
          'sale_restorations',
          _restorationValues(
            id: 'restoration-002',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      expect(
        await _tableCount(
          database,
          'sale_restorations',
        ),
        1,
      );
    });

    test('rejects missing original Sale foreign key', () async {
      await expectLater(
        database.insert(
          'sale_restorations',
          _restorationValues(
            originalSaleId: 'sale-missing',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      expect(
        await _tableCount(
          database,
          'sale_restorations',
        ),
        0,
      );
    });

    test('rejects invalid Restoration Item foreign keys', () async {
      await database.insert(
        'sale_restorations',
        _restorationValues(),
      );

      await expectLater(
        database.insert(
          'sale_restoration_items',
          _restorationItemValues(
            id: 'restoration-item-missing-header',
            restorationId: 'restoration-missing',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      await expectLater(
        database.insert(
          'sale_restoration_items',
          _restorationItemValues(
            id: 'restoration-item-missing-original',
            originalSaleItemId: 'sale-item-missing',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      expect(
        await _tableCount(
          database,
          'sale_restoration_items',
        ),
        0,
      );
    });

    test('allows multiple null Product reversal IDs', () async {
      await database.insert(
        'inventory_movements',
        _productMovementValues(
          id: 'product-null-001',
        ),
      );

      await database.insert(
        'inventory_movements',
        _productMovementValues(
          id: 'product-null-002',
        ),
      );

      expect(
        await _tableCount(
          database,
          'inventory_movements',
        ),
        2,
      );
    });

    test('allows multiple null Ingredient reversal IDs', () async {
      await database.insert(
        'ingredient_movements',
        _ingredientMovementValues(
          id: 'ingredient-null-001',
        ),
      );

      await database.insert(
        'ingredient_movements',
        _ingredientMovementValues(
          id: 'ingredient-null-002',
        ),
      );

      expect(
        await _tableCount(
          database,
          'ingredient_movements',
        ),
        2,
      );
    });

    test('rejects duplicate Product reversal', () async {
      await database.insert(
        'inventory_movements',
        _productMovementValues(
          id: 'product-restoration-001',
          sourceRestorationId: 'restoration-001',
          reversalOfMovementId: 'product-original-movement-001',
        ),
      );

      await expectLater(
        database.insert(
          'inventory_movements',
          _productMovementValues(
            id: 'product-restoration-002',
            sourceRestorationId: 'restoration-002',
            reversalOfMovementId: 'product-original-movement-001',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      expect(
        await _tableCount(
          database,
          'inventory_movements',
        ),
        1,
      );
    });

    test('rejects duplicate Ingredient reversal', () async {
      await database.insert(
        'ingredient_movements',
        _ingredientMovementValues(
          id: 'ingredient-restoration-001',
          sourceRestorationId: 'restoration-001',
          reversalOfMovementId: 'ingredient-original-movement-001',
        ),
      );

      await expectLater(
        database.insert(
          'ingredient_movements',
          _ingredientMovementValues(
            id: 'ingredient-restoration-002',
            sourceRestorationId: 'restoration-002',
            reversalOfMovementId: 'ingredient-original-movement-001',
          ),
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );

      expect(
        await _tableCount(
          database,
          'ingredient_movements',
        ),
        1,
      );
    });

    test('passes foreign-key integrity after valid data', () async {
      await database.insert(
        'sale_restorations',
        _restorationValues(),
      );

      await database.insert(
        'sale_restoration_items',
        _restorationItemValues(),
      );

      final List<Map<String, Object?>> violations = await database.rawQuery(
        'PRAGMA foreign_key_check',
      );

      expect(
        violations,
        isEmpty,
      );
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

Future<int> _tableCount(
  Database database,
  String table,
) async {
  final List<Map<String, Object?>> rows = await database.rawQuery(
    'SELECT COUNT(*) AS row_count FROM $table',
  );

  return (rows.single['row_count'] as num).toInt();
}

Map<String, Object?> _restorationValues({
  String id = 'restoration-001',
  String transactionNumber = 'VOID-0001',
  String originalSaleId = 'sale-001',
  String operation = 'VOID',
}) {
  return <String, Object?>{
    'id': id,
    'restoration_transaction_number': transactionNumber,
    'original_sale_id': originalSaleId,
    'operation': operation,
    'reason': 'Customer transaction voided',
    'subtotal': -200.0,
    'discount': -20.0,
    'net_sales': -180.0,
    'cost': -50.0,
    'cogs': -50.0,
    'gross_profit': -130.0,
    'gross_margin': 72.222222,
    'performed_by': 'user-001',
    'device_id': 'device-001',
    'occurred_at': '2026-09-15T08:00:00.000Z',
    'sync_status': 'PENDING',
  };
}

Map<String, Object?> _restorationItemValues({
  String id = 'restoration-item-001',
  String restorationId = 'restoration-001',
  String originalSaleItemId = 'sale-item-001',
}) {
  return <String, Object?>{
    'id': id,
    'restoration_id': restorationId,
    'original_sale_item_id': originalSaleItemId,
    'product_id': 'product-001',
    'sku': 'SKU-001',
    'product_name': 'Test Product',
    'quantity': 2.0,
    'selling_price': 100.0,
    'discount': 20.0,
    'net_amount': 180.0,
    'unit_cost': 25.0,
    'cogs': 50.0,
    'recipe_version': null,
    'ingredient_cost_json': null,
  };
}

Map<String, Object?> _productMovementValues({
  required String id,
  String? sourceRestorationId,
  String? reversalOfMovementId,
}) {
  return <String, Object?>{
    'id': id,
    'quantity': 2.0,
    'reversal_of_movement_id': reversalOfMovementId,
    'source_restoration_id': sourceRestorationId,
  };
}

Map<String, Object?> _ingredientMovementValues({
  required String id,
  String? sourceRestorationId,
  String? reversalOfMovementId,
}) {
  return <String, Object?>{
    'id': id,
    'quantity': 100.0,
    'reversal_of_movement_id': reversalOfMovementId,
    'source_restoration_id': sourceRestorationId,
  };
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

Future<void> _insertOriginalSale(
  Database database,
) async {
  await database.insert(
    'sales',
    const <String, Object?>{
      'id': 'sale-001',
      'transaction_number': 'TXN-0001',
      'cogs': 50.0,
    },
  );

  await database.insert(
    'sale_items',
    const <String, Object?>{
      'id': 'sale-item-001',
      'transaction_id': 'sale-001',
      'unit_cost': 25.0,
      'cogs': 50.0,
    },
  );
}
