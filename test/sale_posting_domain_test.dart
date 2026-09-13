import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/sale_posting.dart';

void main() {
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
    String paymentType = 'CASH',
    double amount = 180,
  }) {
    return SalePostingPayment(
      id: id,
      paymentType: paymentType,
      amount: amount,
      createdAt: DateTime.utc(2026, 9, 13, 8),
    );
  }

  SalePostingRequest buildRequest({
    List<SalePostingItem>? items,
    List<SalePostingPayment>? payments,
  }) {
    return SalePostingRequest(
      saleId: 'sale-001',
      transactionNumber: 'TXN-0001',
      storeId: 'store-001',
      deviceId: 'device-001',
      cashierId: 'user-001',
      occurredAt: DateTime.utc(2026, 9, 13, 8),
      items: items ?? <SalePostingItem>[buildItem()],
      payments: payments ?? <SalePostingPayment>[buildPayment()],
    );
  }

  group('Sale Posting Item', () {
    test('calculates gross and net amounts', () {
      final SalePostingItem item = buildItem();

      expect(item.grossAmount, 200);
      expect(item.netAmount, 180);
      expect(item.validate, returnsNormally);
    });

    test('rejects invalid quantity and discount', () {
      expect(
        () => buildItem(quantity: 0).validate(),
        throwsFormatException,
      );

      expect(
        () => buildItem(discount: 201).validate(),
        throwsFormatException,
      );
    });

    test('creates normalized consumption request', () {
      final request = buildItem(
        id: ' item-001 ',
        productId: ' product-001 ',
        productSku: ' sku-001 ',
      ).toConsumptionRequest(
        saleId: ' sale-001 ',
        storeId: ' store-001 ',
        occurredAt: DateTime.utc(2026, 9, 13, 8),
        performedBy: ' user-001 ',
        deviceId: ' device-001 ',
      );

      expect(request.saleId, 'sale-001');
      expect(request.saleItemId, 'item-001');
      expect(request.productId, 'product-001');
      expect(request.productSku, 'SKU-001');
      expect(request.performedBy, 'user-001');
      expect(request.deviceId, 'device-001');
      expect(request.occurredAt.isUtc, isTrue);
    });
  });

  group('Sale Posting Request', () {
    test('calculates balanced totals', () {
      final SalePostingRequest request = buildRequest();

      expect(request.subtotal, 200);
      expect(request.totalDiscount, 20);
      expect(request.grandTotal, 180);
      expect(request.totalPayments, 180);
      expect(request.paymentsBalanced, isTrue);
      expect(request.validate, returnsNormally);
    });

    test('rejects an unbalanced payment', () {
      final SalePostingRequest request = buildRequest(
        payments: <SalePostingPayment>[
          buildPayment(amount: 170),
        ],
      );

      expect(request.paymentsBalanced, isFalse);
      expect(request.validate, throwsFormatException);
    });

    test('rejects empty items and payments', () {
      expect(
        () => buildRequest(
          items: const <SalePostingItem>[],
        ).validate(),
        throwsFormatException,
      );

      expect(
        () => buildRequest(
          payments: const <SalePostingPayment>[],
        ).validate(),
        throwsFormatException,
      );
    });

    test('creates one consumption request per item', () {
      final SalePostingRequest request = buildRequest();

      final consumptionRequests = request.toConsumptionRequests();

      expect(consumptionRequests, hasLength(1));
      expect(consumptionRequests.single.saleId, 'sale-001');
      expect(consumptionRequests.single.saleItemId, 'sale-item-001');
    });

    test('protects copied collections', () {
      final List<SalePostingItem> items = <SalePostingItem>[
        buildItem(),
      ];

      final List<SalePostingPayment> payments = <SalePostingPayment>[
        buildPayment(),
      ];

      final SalePostingRequest request = buildRequest(
        items: items,
        payments: payments,
      );

      items.clear();
      payments.clear();

      expect(request.items, hasLength(1));
      expect(request.payments, hasLength(1));
      expect(
        () => request.items.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => request.payments.clear(),
        throwsUnsupportedError,
      );
    });
  });

  group('Sale Posting amount comparison', () {
    test('uses the configured tolerance', () {
      expect(
        salePostingAmountsEqual(100, 100.005),
        isTrue,
      );

      expect(
        salePostingAmountsEqual(100, 100.02),
        isFalse,
      );

      expect(
        salePostingAmountsEqual(double.nan, 100),
        isFalse,
      );
    });
  });
}
