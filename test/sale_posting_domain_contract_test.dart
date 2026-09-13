import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File domainFile = File(
      'lib/domain/models/sale_posting.dart',
    );

    expect(
      domainFile.existsSync(),
      isTrue,
      reason: 'Sale Posting domain model must exist.',
    );

    source = domainFile.readAsStringSync();
  });

  group('Sale Posting domain contract', () {
    test('defines Sale Posting request', () {
      expect(
        source,
        contains(
          'class SalePostingRequest',
        ),
      );

      for (final String field in <String>[
        'saleId',
        'transactionNumber',
        'storeId',
        'deviceId',
        'cashierId',
        'occurredAt',
        'items',
        'payments',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'SalePostingRequest must define $field.',
        );
      }
    });

    test('defines Sale Posting item', () {
      expect(
        source,
        contains(
          'class SalePostingItem',
        ),
      );

      for (final String field in <String>[
        'id',
        'productId',
        'productSku',
        'productName',
        'quantity',
        'sellingPrice',
        'discount',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'SalePostingItem must define $field.',
        );
      }
    });

    test('defines Sale Posting payment', () {
      expect(
        source,
        contains(
          'class SalePostingPayment',
        ),
      );

      for (final String field in <String>[
        'id',
        'paymentType',
        'amount',
        'referenceNumber',
        'createdAt',
      ]) {
        expect(
          source,
          contains(field),
          reason: 'SalePostingPayment must define $field.',
        );
      }
    });

    test('provides item monetary calculations', () {
      expect(
        source,
        contains(
          'double get grossAmount',
        ),
      );

      expect(
        source,
        contains(
          'double get netAmount',
        ),
      );
    });

    test('provides sale monetary calculations', () {
      expect(
        source,
        contains(
          'double get subtotal',
        ),
      );

      expect(
        source,
        contains(
          'double get totalDiscount',
        ),
      );

      expect(
        source,
        contains(
          'double get grandTotal',
        ),
      );

      expect(
        source,
        contains(
          'double get totalPayments',
        ),
      );
    });

    test('provides payment balance validation', () {
      expect(
        source,
        contains(
          'bool get paymentsBalanced',
        ),
      );

      expect(
        source,
        contains(
          'paymentTolerance',
        ),
      );
    });

    test('defines domain validation methods', () {
      expect(
        source,
        contains(
          'void validate()',
        ),
      );

      expect(
        source,
        contains(
          'items.isEmpty',
        ),
      );

      expect(
        source,
        contains(
          'payments.isEmpty',
        ),
      );

      expect(
        source,
        contains(
          'Duplicate Sale Item ID',
        ),
      );

      expect(
        source,
        contains(
          'Duplicate Payment ID',
        ),
      );

      expect(
        source,
        contains(
          'Payment total must equal',
        ),
      );
    });

    test('protects immutable collections', () {
      expect(
        source,
        contains(
          'List<SalePostingItem>.unmodifiable',
        ),
      );

      expect(
        source,
        contains(
          'List<SalePostingPayment>.unmodifiable',
        ),
      );
    });

    test('creates Sale Consumption requests', () {
      expect(
        source,
        contains(
          'SaleConsumptionRequest',
        ),
      );

      expect(
        source,
        contains(
          'toConsumptionRequest',
        ),
      );

      for (final String mapping in <String>[
        'saleId:',
        'saleItemId:',
        'storeId:',
        'productId:',
        'productSku:',
        'quantitySold:',
        'occurredAt:',
        'performedBy:',
        'deviceId:',
      ]) {
        expect(
          source,
          contains(mapping),
          reason: 'Consumption mapping must include $mapping.',
        );
      }
    });

    test('normalizes persistence values', () {
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
          'toUtc()',
        ),
      );
    });
  });
}
