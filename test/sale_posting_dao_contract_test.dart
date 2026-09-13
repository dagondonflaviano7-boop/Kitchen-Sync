import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File daoFile = File(
      'lib/data/local/daos/sale_posting_dao.dart',
    );

    expect(
      daoFile.existsSync(),
      isTrue,
      reason: 'Sale Posting DAO must exist.',
    );

    source = daoFile.readAsStringSync();
  });

  group('Sale Posting DAO contract', () {
    test('defines Sale Posting DAO', () {
      expect(
        source,
        contains(
          'class SalePostingDao',
        ),
      );

      expect(
        source,
        contains(
          'const SalePostingDao()',
        ),
      );
    });

    test('uses transaction-compatible database executor', () {
      expect(
        source,
        contains(
          "import 'package:sqflite/sqflite.dart'",
        ),
      );

      expect(
        source,
        contains(
          'DatabaseExecutor database',
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'database.transaction(',
          ),
        ),
        reason: 'The DAO must use the transaction supplied by its caller.',
      );
    });

    test('accepts Sale Posting request', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/domain/models/sale_posting.dart'",
        ),
      );

      expect(
        source,
        contains(
          'SalePostingRequest request',
        ),
      );
    });

    test('detects duplicate transaction number per store', () {
      expect(
        source,
        contains(
          'Future<bool> saleExists',
        ),
      );

      expect(
        source,
        contains(
          "'sales'",
        ),
      );

      expect(
        source,
        contains(
          'store_id = ? AND transaction_number = ?',
        ),
      );

      expect(
        source,
        contains(
          "columns: const <String>['id']",
        ),
      );

      expect(
        source,
        contains(
          'limit: 1',
        ),
      );
    });

    test('inserts the sale header', () {
      expect(
        source,
        contains(
          'Future<void> insertSale',
        ),
      );

      for (final String column in <String>[
        "'id'",
        "'transaction_number'",
        "'store_id'",
        "'device_id'",
        "'cashier_id'",
        "'date_time'",
        "'subtotal'",
        "'discount'",
        "'vat'",
        "'net_sales'",
        "'grand_total'",
        "'cost'",
        "'cogs'",
        "'gross_profit'",
        "'gross_margin'",
        "'status'",
        "'sync_status'",
      ]) {
        expect(
          source,
          contains(column),
          reason: 'Sale header must include $column.',
        );
      }
    });

    test('inserts sale items', () {
      expect(
        source,
        contains(
          'Future<void> insertSaleItems',
        ),
      );

      expect(
        source,
        contains(
          'for (final SalePostingItem item in request.items)',
        ),
      );

      for (final String column in <String>[
        "'id'",
        "'transaction_id'",
        "'product_id'",
        "'sku'",
        "'product_name'",
        "'quantity'",
        "'selling_price'",
        "'discount'",
        "'net_amount'",
        "'unit_cost'",
        "'cogs'",
        "'recipe_version'",
        "'ingredient_cost_json'",
      ]) {
        expect(
          source,
          contains(column),
          reason: 'Sale item must include $column.',
        );
      }
    });

    test('inserts payments', () {
      expect(
        source,
        contains(
          'Future<void> insertPayments',
        ),
      );

      expect(
        source,
        contains(
          'for (final SalePostingPayment payment in request.payments)',
        ),
      );

      for (final String column in <String>[
        "'id'",
        "'transaction_id'",
        "'payment_type'",
        "'amount'",
        "'reference_number'",
        "'created_at'",
      ]) {
        expect(
          source,
          contains(column),
          reason: 'Payment must include $column.',
        );
      }
    });

    test('uses abort conflict handling', () {
      expect(
        source,
        contains(
          'ConflictAlgorithm.abort',
        ),
      );
    });

    test('provides complete posting entry point', () {
      expect(
        source,
        contains(
          'Future<void> insertPosting',
        ),
      );

      expect(
        source,
        contains(
          'await insertSale(',
        ),
      );

      expect(
        source,
        contains(
          'await insertSaleItems(',
        ),
      );

      expect(
        source,
        contains(
          'await insertPayments(',
        ),
      );
    });

    test('validates before writing', () {
      expect(
        source,
        contains(
          'request.validate()',
        ),
      );

      expect(
        source,
        contains(
          'Sale has already been posted.',
        ),
      );
    });

    test('normalizes persisted values', () {
      expect(
        source,
        contains(
          'trim()',
        ),
      );

      expect(
        source,
        contains(
          'toUpperCase()',
        ),
      );

      expect(
        source,
        contains(
          'toUtc().toIso8601String()',
        ),
      );
    });
  });
}
