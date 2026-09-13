import 'package:kitchen_sync/domain/models/sale_posting.dart';
import 'package:sqflite/sqflite.dart';

class SalePostingDao {
  const SalePostingDao();

  Future<bool> saleExists(
    DatabaseExecutor database, {
    required String storeId,
    required String transactionNumber,
  }) async {
    final String normalizedStoreId = storeId.trim();
    final String normalizedTransactionNumber =
        transactionNumber.trim().toUpperCase();

    if (normalizedStoreId.isEmpty) {
      throw const FormatException(
        'Store ID is required.',
      );
    }

    if (normalizedTransactionNumber.isEmpty) {
      throw const FormatException(
        'Transaction Number is required.',
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'sales',
      columns: const <String>['id'],
      where: 'store_id = ? AND transaction_number = ?',
      whereArgs: <Object?>[
        normalizedStoreId,
        normalizedTransactionNumber,
      ],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> insertSale(
    DatabaseExecutor database,
    SalePostingRequest request,
  ) async {
    request.validate();

    await database.insert(
      'sales',
      <String, Object?>{
        'id': request.saleId.trim(),
        'transaction_number': request.transactionNumber.trim().toUpperCase(),
        'store_id': request.storeId.trim(),
        'device_id': request.deviceId.trim(),
        'cashier_id': request.cashierId.trim(),
        'date_time': request.occurredAt.toUtc().toIso8601String(),
        'subtotal': request.subtotal,
        'discount': request.totalDiscount,
        'vat': 0.0,
        'net_sales': request.grandTotal,
        'grand_total': request.grandTotal,
        'cost': 0.0,
        'cogs': 0.0,
        'gross_profit': 0.0,
        'gross_margin': 0.0,
        'status': 'COMPLETED',
        'sync_status': 'PENDING',
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> insertSaleItems(
    DatabaseExecutor database,
    SalePostingRequest request,
  ) async {
    request.validate();

    for (final SalePostingItem item in request.items) {
      item.validate();

      await database.insert(
        'sale_items',
        <String, Object?>{
          'id': item.id.trim(),
          'transaction_id': request.saleId.trim(),
          'product_id': item.productId.trim(),
          'sku': item.productSku.trim().toUpperCase(),
          'product_name': item.productName.trim(),
          'quantity': item.quantity,
          'selling_price': item.sellingPrice,
          'discount': item.discount,
          'net_amount': item.netAmount,
          'unit_cost': 0.0,
          'cogs': 0.0,
          'recipe_version': null,
          'ingredient_cost_json': null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> insertPayments(
    DatabaseExecutor database,
    SalePostingRequest request,
  ) async {
    request.validate();

    for (final SalePostingPayment payment in request.payments) {
      payment.validate();

      await database.insert(
        'payments',
        <String, Object?>{
          'id': payment.id.trim(),
          'transaction_id': request.saleId.trim(),
          'payment_type': payment.paymentType.trim().toUpperCase(),
          'amount': payment.amount,
          'reference_number': _optionalText(
            payment.referenceNumber,
          ),
          'created_at': payment.createdAt.toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> insertPosting(
    DatabaseExecutor database,
    SalePostingRequest request,
  ) async {
    request.validate();

    final bool alreadyPosted = await saleExists(
      database,
      storeId: request.storeId,
      transactionNumber: request.transactionNumber,
    );

    if (alreadyPosted) {
      throw StateError(
        'Sale has already been posted.',
      );
    }

    await insertSale(
      database,
      request,
    );

    await insertSaleItems(
      database,
      request,
    );

    await insertPayments(
      database,
      request,
    );
  }
}

String? _optionalText(
  String? value,
) {
  final String normalized = value?.trim() ?? '';

  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}
