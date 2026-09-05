import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/daos/product_dao.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v7.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v8.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
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

          for (final String statement in migrationV8) {
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
    MasterSyncStatus syncStatus = MasterSyncStatus.pending,
    int serverVersion = 0,
    bool active = true,
    DateTime? deletedAt,
  }) {
    return Product(
      id: id,
      sku: sku,
      productName: 'Sync Product',
      cost: 10,
      retailPrice: 20,
      vat: 0,
      active: active,
      inventoryMode: ProductInventoryMode.direct,
      costingMethod: ProductCostingMethod.manual,
      createdAt: DateTime.utc(
        2026,
        9,
        4,
      ),
      updatedAt: DateTime.utc(
        2026,
        9,
        5,
      ),
      syncStatus: syncStatus,
      serverVersion: serverVersion,
      deletedAt: deletedAt,
    );
  }

  group('Product DAO sync lifecycle execution', () {
    test(
      'findPending returns Pending and Error Products',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        await productDao.upsert(
          database,
          buildProduct(
            id: 'product-002',
            sku: 'SKU-002',
            syncStatus: MasterSyncStatus.error,
          ),
        );

        await productDao.upsert(
          database,
          buildProduct(
            id: 'product-003',
            sku: 'SKU-003',
            syncStatus: MasterSyncStatus.synced,
          ),
        );

        final List<Product> pending = await productDao.findPending(
          database,
        );

        expect(pending, hasLength(2));

        expect(
          pending.map(
            (Product product) {
              return product.syncStatus;
            },
          ).toSet(),
          <MasterSyncStatus>{
            MasterSyncStatus.pending,
            MasterSyncStatus.error,
          },
        );
      },
    );

    test(
      'findPending rejects an invalid limit',
      () {
        expect(
          () => productDao.findPending(
            database,
            limit: 0,
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'markSyncing stores Syncing status',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        await productDao.markSyncing(
          database,
          'product-001',
        );

        final Product stored = (await productDao.findByIdIncludingInactive(
          database,
          'product-001',
        ))!;

        expect(
          stored.syncStatus,
          MasterSyncStatus.syncing,
        );
      },
    );

    test(
      'markSynced stores status and server version',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        await productDao.markSynced(
          database,
          'product-001',
          serverVersion: 9,
        );

        final Product stored = (await productDao.findByIdIncludingInactive(
          database,
          'product-001',
        ))!;

        expect(
          stored.syncStatus,
          MasterSyncStatus.synced,
        );

        expect(stored.serverVersion, 9);
      },
    );

    test(
      'markSynced rejects a negative version',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        expect(
          () => productDao.markSynced(
            database,
            'product-001',
            serverVersion: -1,
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'markSyncError stores Error status',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        await productDao.markSyncError(
          database,
          'product-001',
        );

        final Product stored = (await productDao.findByIdIncludingInactive(
          database,
          'product-001',
        ))!;

        expect(
          stored.syncStatus,
          MasterSyncStatus.error,
        );
      },
    );

    test(
      'softDelete creates a Pending tombstone',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        final DateTime timestamp = DateTime.utc(
          2026,
          9,
          7,
        );

        await productDao.softDelete(
          database,
          'product-001',
          deletedAt: timestamp,
        );

        final Product stored = (await productDao.findByIdIncludingInactive(
          database,
          'product-001',
        ))!;

        expect(stored.active, isFalse);
        expect(stored.isDeleted, isTrue);
        expect(stored.deletedAt, timestamp);

        expect(
          stored.syncStatus,
          MasterSyncStatus.pending,
        );
      },
    );

    test(
      'softDelete rejects a second deletion',
      () async {
        await productDao.upsert(
          database,
          buildProduct(),
        );

        await productDao.softDelete(
          database,
          'product-001',
        );

        expect(
          () => productDao.softDelete(
            database,
            'product-001',
          ),
          throwsStateError,
        );
      },
    );

    test(
      'upsertRemote stores Product as Synced',
      () async {
        await productDao.upsertRemote(
          database,
          buildProduct(
            syncStatus: MasterSyncStatus.pending,
            serverVersion: 12,
          ),
        );

        final Product stored = (await productDao.findByIdIncludingInactive(
          database,
          'product-001',
        ))!;

        expect(
          stored.syncStatus,
          MasterSyncStatus.synced,
        );

        expect(stored.serverVersion, 12);
      },
    );
  });
}
