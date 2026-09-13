import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/daos/sale_posting_dao.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';
import 'package:kitchen_sync/domain/models/sale_posting.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_posting_costing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  const SalePostingDao dao = SalePostingDao();

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

    for (final String statement in migrationV1) {
      await database.execute(statement);
    }
  });

  tearDown(() async {
    await database.close();
  });

  SalePostingItem buildItem({
    String id = 'sale-item-001',
    String productId = 'product-001',
    String productSku = 'sku-001',
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
    String paymentType = 'cash',
    double amount = 180,
    String? referenceNumber,
    DateTime? createdAt,
  }) {
    return SalePostingPayment(
      id: id,
      paymentType: paymentType,
      amount: amount,
      referenceNumber: referenceNumber,
      createdAt: createdAt ??
          DateTime.utc(
            2026,
            9,
            13,
            8,
          ),
    );
  }

  SalePostingRequest buildRequest({
    String saleId = 'sale-001',
    String transactionNumber = 'txn-0001',
    String storeId = 'store-001',
    String deviceId = 'device-001',
    String cashierId = 'user-001',
    DateTime? occurredAt,
    List<SalePostingItem>? items,
    List<SalePostingPayment>? payments,
  }) {
    return SalePostingRequest(
      saleId: saleId,
      transactionNumber: transactionNumber,
      storeId: storeId,
      deviceId: deviceId,
      cashierId: cashierId,
      occurredAt: occurredAt ??
          DateTime.utc(
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

  SalePostingCostingSnapshot buildCosting(
    SalePostingRequest request, {
    ProductInventoryMode inventoryMode = ProductInventoryMode.direct,
    double unitCost = 25,
    String? recipeId,
    String? ingredientCostJson,
  }) {
    final List<SalePostingItemCostSnapshot> itemCosts = request.items.map(
      (SalePostingItem item) {
        final bool ignoresInventory =
            inventoryMode == ProductInventoryMode.none;

        final double resolvedUnitCost = ignoresInventory ? 0 : unitCost;

        final double resolvedCogs = item.quantity * resolvedUnitCost;

        return SalePostingItemCostSnapshot(
          saleItemId: item.id.trim(),
          productId: item.productId.trim(),
          inventoryMode: inventoryMode,
          quantity: item.quantity,
          netAmount: item.netAmount,
          unitCost: resolvedUnitCost,
          cogs: resolvedCogs,
          recipeId: inventoryMode == ProductInventoryMode.recipe
              ? recipeId ?? 'recipe-001'
              : null,
          recipeVersion: null,
          ingredientCostJson: inventoryMode == ProductInventoryMode.recipe
              ? ingredientCostJson ??
                  '{"recipeId":"recipe-001",'
                      '"ingredients":[],'
                      '"totalIngredientCost":'
                      '${resolvedCogs.toString()}}'
              : null,
        );
      },
    ).toList(growable: false);

    final SalePostingCostingSnapshot costing = SalePostingCostingSnapshot(
      saleId: request.saleId.trim(),
      request: request,
      items: itemCosts,
    );

    costing.validate();
    return costing;
  }

  Future<void> insertPostingWithCost(
    DatabaseExecutor database,
    SalePostingRequest request,
  ) async {
    await dao.insertPosting(
      database,
      request,
      buildCosting(request),
    );
  }

  Future<void> insertSaleWithCost(
    DatabaseExecutor database,
    SalePostingRequest request,
  ) async {
    await dao.insertSale(
      database,
      request,
      buildCosting(request),
    );
  }

  Future<int> tableCount(
    String table,
  ) async {
    final List<Map<String, Object?>> rows = await database.rawQuery(
      'SELECT COUNT(*) AS row_count FROM $table',
    );

    return (rows.single['row_count'] as num).toInt();
  }

  group('Sale Posting DAO execution', () {
    test(
      'inserts complete sale posting',
      () async {
        final SalePostingRequest request = buildRequest();

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              request,
            );
          },
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

        final Map<String, Object?> sale =
            (await database.query('sales')).single;

        expect(
          sale['id'],
          'sale-001',
        );

        expect(
          sale['transaction_number'],
          'TXN-0001',
        );

        expect(
          sale['store_id'],
          'store-001',
        );

        expect(
          sale['device_id'],
          'device-001',
        );

        expect(
          sale['cashier_id'],
          'user-001',
        );

        expect(
          sale['subtotal'],
          200.0,
        );

        expect(
          sale['discount'],
          20.0,
        );

        expect(
          sale['net_sales'],
          180.0,
        );

        expect(
          sale['grand_total'],
          180.0,
        );

        expect(
          sale['cost'],
          50.0,
        );

        expect(
          sale['cogs'],
          50.0,
        );

        expect(
          sale['gross_profit'],
          130.0,
        );

        expect(
          sale['gross_margin'],
          closeTo(
            72.222222,
            0.0001,
          ),
        );

        expect(
          sale['status'],
          'COMPLETED',
        );

        expect(
          sale['sync_status'],
          'PENDING',
        );
      },
    );

    test(
      'inserts normalized sale item',
      () async {
        final SalePostingRequest request = buildRequest(
          items: <SalePostingItem>[
            buildItem(
              id: ' item-001 ',
              productId: ' product-001 ',
              productSku: ' sku-001 ',
              productName: ' Test Product ',
            ),
          ],
        );

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              request,
            );
          },
        );

        final Map<String, Object?> item =
            (await database.query('sale_items')).single;

        expect(
          item['id'],
          'item-001',
        );

        expect(
          item['transaction_id'],
          'sale-001',
        );

        expect(
          item['product_id'],
          'product-001',
        );

        expect(
          item['sku'],
          'SKU-001',
        );

        expect(
          item['product_name'],
          'Test Product',
        );

        expect(
          item['quantity'],
          2.0,
        );

        expect(
          item['selling_price'],
          100.0,
        );

        expect(
          item['discount'],
          20.0,
        );

        expect(
          item['net_amount'],
          180.0,
        );

        expect(
          item['unit_cost'],
          25.0,
        );

        expect(
          item['cogs'],
          50.0,
        );

        expect(
          item['recipe_version'],
          isNull,
        );

        expect(
          item['ingredient_cost_json'],
          isNull,
        );
      },
    );

    test(
      'inserts normalized payment',
      () async {
        final SalePostingRequest request = buildRequest(
          payments: <SalePostingPayment>[
            buildPayment(
              id: ' payment-001 ',
              paymentType: ' card ',
              referenceNumber: ' ref-001 ',
            ),
          ],
        );

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              request,
            );
          },
        );

        final Map<String, Object?> payment =
            (await database.query('payments')).single;

        expect(
          payment['id'],
          'payment-001',
        );

        expect(
          payment['transaction_id'],
          'sale-001',
        );

        expect(
          payment['payment_type'],
          'CARD',
        );

        expect(
          payment['amount'],
          180.0,
        );

        expect(
          payment['reference_number'],
          'ref-001',
        );

        expect(
          payment['created_at'],
          DateTime.utc(
            2026,
            9,
            13,
            8,
          ).toIso8601String(),
        );
      },
    );

    test(
      'stores blank optional payment reference as null',
      () async {
        final SalePostingRequest request = buildRequest(
          payments: <SalePostingPayment>[
            buildPayment(
              referenceNumber: '   ',
            ),
          ],
        );

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              request,
            );
          },
        );

        final Map<String, Object?> payment =
            (await database.query('payments')).single;

        expect(
          payment['reference_number'],
          isNull,
        );
      },
    );

    test(
      'detects an existing sale',
      () async {
        final SalePostingRequest request = buildRequest();

        expect(
          await dao.saleExists(
            database,
            storeId: request.storeId,
            transactionNumber: request.transactionNumber,
          ),
          isFalse,
        );

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              request,
            );
          },
        );

        expect(
          await dao.saleExists(
            database,
            storeId: ' store-001 ',
            transactionNumber: ' txn-0001 ',
          ),
          isTrue,
        );
      },
    );

    test(
      'rejects duplicate transaction number in same store',
      () async {
        final SalePostingRequest first = buildRequest();

        final SalePostingRequest duplicate = buildRequest(
          saleId: 'sale-002',
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

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              first,
            );
          },
        );

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await insertPostingWithCost(
                transaction,
                duplicate,
              );
            },
          ),
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
      },
    );

    test(
      'allows same transaction number in another store',
      () async {
        final SalePostingRequest first = buildRequest();

        final SalePostingRequest second = buildRequest(
          saleId: 'sale-002',
          storeId: 'store-002',
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

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              first,
            );
          },
        );

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              second,
            );
          },
        );

        expect(
          await tableCount('sales'),
          2,
        );

        expect(
          await tableCount('sale_items'),
          2,
        );

        expect(
          await tableCount('payments'),
          2,
        );
      },
    );

    test(
      'rejects invalid request before writing',
      () async {
        final SalePostingRequest invalid = buildRequest(
          payments: <SalePostingPayment>[
            buildPayment(
              amount: 170,
            ),
          ],
        );

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await insertPostingWithCost(
                transaction,
                invalid,
              );
            },
          ),
          throwsFormatException,
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
      },
    );

    test(
      'rolls back sale when item insertion fails',
      () async {
        await insertSaleWithCost(
          database,
          buildRequest(
            saleId: 'existing-sale',
            transactionNumber: 'EXISTING-TXN-ITEM',
            items: <SalePostingItem>[
              buildItem(
                id: 'existing-item',
              ),
            ],
            payments: <SalePostingPayment>[
              buildPayment(
                id: 'existing-payment',
              ),
            ],
          ),
        );

        await database.insert(
          'sale_items',
          <String, Object?>{
            'id': 'sale-item-001',
            'transaction_id': 'existing-sale',
            'product_id': 'existing-product',
            'sku': 'EXISTING',
            'product_name': 'Existing Product',
            'quantity': 1.0,
            'selling_price': 1.0,
            'discount': 0.0,
            'net_amount': 1.0,
            'unit_cost': 0.0,
            'cogs': 0.0,
            'recipe_version': null,
            'ingredient_cost_json': null,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        final SalePostingRequest request = buildRequest();

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await insertPostingWithCost(
                transaction,
                request,
              );
            },
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );

        expect(
          await tableCount('sales'),
          1,
          reason: 'The pre-existing parent sale must remain.',
        );

        expect(
          await tableCount('sale_items'),
          1,
          reason: 'Only the pre-existing conflicting item must remain.',
        );

        expect(
          await tableCount('payments'),
          0,
          reason: 'The failed posting must not insert its payment.',
        );
      },
    );

    test(
      'rolls back sale and items when payment insertion fails',
      () async {
        await insertSaleWithCost(
          database,
          buildRequest(
            saleId: 'existing-sale',
            transactionNumber: 'EXISTING-TXN-PAYMENT',
            items: <SalePostingItem>[
              buildItem(
                id: 'existing-item',
              ),
            ],
            payments: <SalePostingPayment>[
              buildPayment(
                id: 'existing-payment',
              ),
            ],
          ),
        );

        await database.insert(
          'payments',
          <String, Object?>{
            'id': 'payment-001',
            'transaction_id': 'existing-sale',
            'payment_type': 'CASH',
            'amount': 1.0,
            'reference_number': null,
            'created_at': DateTime.utc(
              2026,
              9,
              13,
            ).toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        final SalePostingRequest request = buildRequest();

        await expectLater(
          database.transaction(
            (Transaction transaction) async {
              await insertPostingWithCost(
                transaction,
                request,
              );
            },
          ),
          throwsA(
            isA<DatabaseException>(),
          ),
        );

        expect(
          await tableCount('sales'),
          1,
          reason: 'The pre-existing parent sale must remain.',
        );

        expect(
          await tableCount('sale_items'),
          0,
          reason: 'The failed posting must roll back its inserted item.',
        );

        expect(
          await tableCount('payments'),
          1,
          reason: 'Only the pre-existing conflicting payment must remain.',
        );
      },
    );

    test(
      'inserts multiple items and payments',
      () async {
        final SalePostingRequest request = buildRequest(
          items: <SalePostingItem>[
            buildItem(),
            buildItem(
              id: 'sale-item-002',
              productId: 'product-002',
              productSku: 'sku-002',
              productName: 'Second Product',
              quantity: 1,
              sellingPrice: 50,
              discount: 0,
            ),
          ],
          payments: <SalePostingPayment>[
            buildPayment(
              amount: 100,
            ),
            buildPayment(
              id: 'payment-002',
              paymentType: 'CARD',
              amount: 130,
              referenceNumber: 'CARD-001',
            ),
          ],
        );

        await database.transaction(
          (Transaction transaction) async {
            await insertPostingWithCost(
              transaction,
              request,
            );
          },
        );

        expect(
          await tableCount('sales'),
          1,
        );

        expect(
          await tableCount('sale_items'),
          2,
        );

        expect(
          await tableCount('payments'),
          2,
        );

        final List<Map<String, Object?>> items = await database.query(
          'sale_items',
          orderBy: 'id',
        );

        expect(
          items[0]['sku'],
          'SKU-001',
        );

        expect(
          items[1]['sku'],
          'SKU-002',
        );

        final List<Map<String, Object?>> payments = await database.query(
          'payments',
          orderBy: 'id',
        );

        expect(
          payments[0]['amount'],
          100.0,
        );

        expect(
          payments[1]['amount'],
          130.0,
        );
      },
    );

    test(
      'rejects blank duplicate lookup arguments',
      () async {
        await expectLater(
          dao.saleExists(
            database,
            storeId: ' ',
            transactionNumber: 'TXN-001',
          ),
          throwsFormatException,
        );

        await expectLater(
          dao.saleExists(
            database,
            storeId: 'store-001',
            transactionNumber: ' ',
          ),
          throwsFormatException,
        );
      },
    );
  });
}
