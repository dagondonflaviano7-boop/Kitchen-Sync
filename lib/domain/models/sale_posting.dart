import 'dart:math' as math;

import 'package:kitchen_sync/domain/models/sale_consumption.dart';

class SalePostingItem {
  final String id;
  final String productId;
  final String productSku;
  final String productName;

  final double quantity;
  final double sellingPrice;
  final double discount;

  const SalePostingItem({
    required this.id,
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    this.discount = 0,
  });

  double get grossAmount {
    return quantity * sellingPrice;
  }

  double get netAmount {
    return grossAmount - discount;
  }

  void validate() {
    _requiredText(
      id,
      'Sale Item ID',
    );

    _requiredText(
      productId,
      'Product ID',
    );

    _requiredText(
      productSku,
      'Product SKU',
    );

    _requiredText(
      productName,
      'Product Name',
    );

    _positiveNumber(
      quantity,
      'Quantity',
    );

    _nonNegativeNumber(
      sellingPrice,
      'Selling Price',
    );

    _nonNegativeNumber(
      discount,
      'Discount',
    );

    if (discount > grossAmount) {
      throw const FormatException(
        'Discount cannot exceed the gross amount.',
      );
    }
  }

  SaleConsumptionRequest toConsumptionRequest({
    required String saleId,
    required String storeId,
    required DateTime occurredAt,
    required String performedBy,
    required String deviceId,
  }) {
    validate();

    final SaleConsumptionRequest request = SaleConsumptionRequest(
      saleId: saleId.trim(),
      saleItemId: id.trim(),
      storeId: storeId.trim(),
      productId: productId.trim(),
      productSku: productSku.trim().toUpperCase(),
      quantitySold: quantity,
      occurredAt: occurredAt.toUtc(),
      performedBy: performedBy.trim(),
      deviceId: deviceId.trim(),
    );

    request.validate();
    return request;
  }
}

class SalePostingPayment {
  final String id;
  final String paymentType;
  final double amount;
  final String? referenceNumber;
  final DateTime createdAt;

  const SalePostingPayment({
    required this.id,
    required this.paymentType,
    required this.amount,
    this.referenceNumber,
    required this.createdAt,
  });

  void validate() {
    _requiredText(
      id,
      'Payment ID',
    );

    _requiredText(
      paymentType,
      'Payment Type',
    );

    _positiveNumber(
      amount,
      'Payment Amount',
    );
  }
}

class SalePostingRequest {
  static const double paymentTolerance = 0.01;

  final String saleId;
  final String transactionNumber;
  final String storeId;
  final String deviceId;
  final String cashierId;
  final DateTime occurredAt;

  final List<SalePostingItem> items;
  final List<SalePostingPayment> payments;

  SalePostingRequest({
    required this.saleId,
    required this.transactionNumber,
    required this.storeId,
    required this.deviceId,
    required this.cashierId,
    required this.occurredAt,
    required List<SalePostingItem> items,
    required List<SalePostingPayment> payments,
  })  : items = List<SalePostingItem>.unmodifiable(
          items,
        ),
        payments = List<SalePostingPayment>.unmodifiable(
          payments,
        );

  double get subtotal {
    return items.fold(
      0,
      (
        double total,
        SalePostingItem item,
      ) {
        return total + item.grossAmount;
      },
    );
  }

  double get totalDiscount {
    return items.fold(
      0,
      (
        double total,
        SalePostingItem item,
      ) {
        return total + item.discount;
      },
    );
  }

  double get grandTotal {
    return subtotal - totalDiscount;
  }

  double get totalPayments {
    return payments.fold(
      0,
      (
        double total,
        SalePostingPayment payment,
      ) {
        return total + payment.amount;
      },
    );
  }

  bool get paymentsBalanced {
    return (totalPayments - grandTotal).abs() <= paymentTolerance;
  }

  List<SaleConsumptionRequest> toConsumptionRequests() {
    validate();

    return List<SaleConsumptionRequest>.unmodifiable(
      items.map(
        (SalePostingItem item) {
          return item.toConsumptionRequest(
            saleId: saleId,
            storeId: storeId,
            occurredAt: occurredAt,
            performedBy: cashierId,
            deviceId: deviceId,
          );
        },
      ),
    );
  }

  void validate() {
    _requiredText(
      saleId,
      'Sale ID',
    );

    _requiredText(
      transactionNumber,
      'Transaction Number',
    );

    _requiredText(
      storeId,
      'Store ID',
    );

    _requiredText(
      deviceId,
      'Device ID',
    );

    _requiredText(
      cashierId,
      'Cashier ID',
    );

    if (items.isEmpty) {
      throw const FormatException(
        'At least one Sale Item is required.',
      );
    }

    if (payments.isEmpty) {
      throw const FormatException(
        'At least one Payment is required.',
      );
    }

    final Set<String> saleItemIds = <String>{};

    for (final SalePostingItem item in items) {
      item.validate();

      final String normalizedId = item.id.trim();

      if (!saleItemIds.add(normalizedId)) {
        throw const FormatException(
          'Duplicate Sale Item ID is not allowed.',
        );
      }
    }

    final Set<String> paymentIds = <String>{};

    for (final SalePostingPayment payment in payments) {
      payment.validate();

      final String normalizedId = payment.id.trim();

      if (!paymentIds.add(normalizedId)) {
        throw const FormatException(
          'Duplicate Payment ID is not allowed.',
        );
      }
    }

    if (!subtotal.isFinite ||
        !totalDiscount.isFinite ||
        !grandTotal.isFinite ||
        !totalPayments.isFinite) {
      throw const FormatException(
        'Sale monetary totals must be valid numbers.',
      );
    }

    if (grandTotal < 0) {
      throw const FormatException(
        'Grand Total cannot be negative.',
      );
    }

    if (!paymentsBalanced) {
      throw FormatException(
        'Payment total must equal the Grand Total. '
        'Expected ${grandTotal.toStringAsFixed(2)}, '
        'received ${totalPayments.toStringAsFixed(2)}.',
      );
    }
  }
}

void _requiredText(
  String value,
  String fieldName,
) {
  if (value.trim().isEmpty) {
    throw FormatException(
      '$fieldName is required.',
    );
  }
}

void _positiveNumber(
  double value,
  String fieldName,
) {
  if (!value.isFinite || value <= 0) {
    throw FormatException(
      '$fieldName must be greater than zero.',
    );
  }
}

void _nonNegativeNumber(
  double value,
  String fieldName,
) {
  if (!value.isFinite || value < 0) {
    throw FormatException(
      '$fieldName cannot be negative.',
    );
  }
}

bool salePostingAmountsEqual(
  double first,
  double second, {
  double tolerance = SalePostingRequest.paymentTolerance,
}) {
  if (!first.isFinite || !second.isFinite || !tolerance.isFinite) {
    return false;
  }

  return math.max(
            first,
            second,
          ) -
          math.min(
            first,
            second,
          ) <=
      tolerance;
}
