import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v7.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'Migration V7 adds Recipe ID and preserves Products',
    () async {
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (
          Database db,
          int version,
        ) async {
          await db.execute(
            '''
            CREATE TABLE products (
              id TEXT PRIMARY KEY,
              sku TEXT NOT NULL UNIQUE,
              product_name TEXT NOT NULL,
              retail_price REAL NOT NULL DEFAULT 0,
              active INTEGER NOT NULL DEFAULT 1,
              inventory_mode TEXT NOT NULL,
              costing_method TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
            ''',
          );

          await db.insert(
            'products',
            <String, Object?>{
              'id': 'product-001',
              'sku': 'SKU-001',
              'product_name': 'Test Product',
              'retail_price': 100,
              'active': 1,
              'inventory_mode': 'RECIPE',
              'costing_method': 'INGREDIENT',
              'created_at': '2026-09-04T00:00:00.000Z',
              'updated_at': '2026-09-04T00:00:00.000Z',
            },
          );
        },
      );

      for (final String statement in migrationV7) {
        await database.execute(statement);
      }

      final List<Map<String, Object?>> columns = await database.rawQuery(
        'PRAGMA table_info(products)',
      );

      expect(
        columns.any(
          (Map<String, Object?> column) {
            return column['name'] == 'recipe_id';
          },
        ),
        isTrue,
      );

      final List<Map<String, Object?>> products = await database.query(
        'products',
      );

      expect(products, hasLength(1));

      expect(
        products.single['id'],
        'product-001',
      );

      expect(
        products.single['recipe_id'],
        isNull,
      );

      await database.update(
        'products',
        <String, Object?>{
          'recipe_id': 'recipe-001',
        },
        where: 'id = ?',
        whereArgs: <Object?>[
          'product-001',
        ],
      );

      final Map<String, Object?> linked = (await database.query(
        'products',
        where: 'id = ?',
        whereArgs: <Object?>[
          'product-001',
        ],
        limit: 1,
      ))
          .single;

      expect(
        linked['recipe_id'],
        'recipe-001',
      );

      final List<Map<String, Object?>> indexes = await database.rawQuery(
        'PRAGMA index_list(products)',
      );

      expect(
        indexes.any(
          (Map<String, Object?> index) {
            return index['name'] == 'idx_products_recipe_id';
          },
        ),
        isTrue,
      );
    },
  );
}
