import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v8.dart';
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
    'Migration V8 adds Product sync metadata '
    'and preserves existing records',
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
              recipe_id TEXT,
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
              'product_name': 'Existing Product',
              'retail_price': 100,
              'active': 1,
              'inventory_mode': 'RECIPE',
              'costing_method': 'INGREDIENT',
              'recipe_id': 'recipe-001',
              'created_at': '2026-09-04T00:00:00.000Z',
              'updated_at': '2026-09-04T00:00:00.000Z',
            },
          );
        },
      );

      for (final String statement in migrationV8) {
        await database.execute(statement);
      }

      final Map<String, Object?> row = (await database.query(
        'products',
        where: 'id = ?',
        whereArgs: const <Object?>[
          'product-001',
        ],
      ))
          .single;

      expect(row['id'], 'product-001');
      expect(row['recipe_id'], 'recipe-001');
      expect(row['sync_status'], 'PENDING');
      expect(row['server_version'], 0);
      expect(row['deleted_at'], isNull);

      final List<Map<String, Object?>> columns = await database.rawQuery(
        'PRAGMA table_info(products)',
      );

      for (final String columnName in <String>[
        'sync_status',
        'server_version',
        'deleted_at',
      ]) {
        expect(
          columns.any(
            (Map<String, Object?> column) {
              return column['name'] == columnName;
            },
          ),
          isTrue,
        );
      }

      final List<Map<String, Object?>> indexes = await database.rawQuery(
        'PRAGMA index_list(products)',
      );

      final Set<Object?> indexNames = indexes.map(
        (Map<String, Object?> index) {
          return index['name'];
        },
      ).toSet();

      expect(
        indexNames,
        contains('idx_products_sync'),
      );

      expect(
        indexNames,
        contains(
          'idx_products_active_deleted',
        ),
      );
    },
  );
}
