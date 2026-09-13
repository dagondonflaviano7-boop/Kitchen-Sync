import 'package:kitchen_sync/domain/models/sale_posting.dart';
import 'package:kitchen_sync/domain/models/sale_posting_costing.dart';
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
    SalePostingCostingSnapshot costing,
  ) async {
    request.validate();
    costing.validate();

    _validateCostingOwnership(
      request,
      costing,
    );

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
        'cost': costing.totalCost,
        'cogs': costing.totalCogs,
        'gross_profit': costing.grossProfit,
        'gross_margin': costing.grossMargin,
        'status': 'COMPLETED',
        'sync_status': 'PENDING',
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> insertSaleItems(
    DatabaseExecutor database,
    SalePostingRequest request,
    SalePostingCostingSnapshot costing,
  ) async {
    request.validate();
    costing.validate();

    _validateCostingOwnership(
      request,
      costing,
    );

    for (final SalePostingItem item in request.items) {
      item.validate();

      final SalePostingItemCostSnapshot itemCost = costing.itemCostFor(
        item.id,
      );

      itemCost.validate();

      if (itemCost.saleItemId.trim() != item.id.trim() ||
          itemCost.productId.trim() != item.productId.trim()) {
        throw const FormatException(
          'Cost snapshot does not match the Sale Item.',
        );
      }

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
          'unit_cost': itemCost.unitCost,
          'cogs': itemCost.cogs,
          'recipe_version': itemCost.recipeVersion,
          'ingredient_cost_json': itemCost.ingredientCostJson,
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
    SalePostingCostingSnapshot costing,
  ) async {
    request.validate();
    costing.validate();

    _validateCostingOwnership(
      request,
      costing,
    );

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
      costing,
    );

    await insertSaleItems(
      database,
      request,
      costing,
    );

    await insertPayments(
      database,
      request,
    );
  }

  void _validateCostingOwnership(
    SalePostingRequest request,
    SalePostingCostingSnapshot costing,
  ) {
    if (costing.saleId.trim() != request.saleId.trim()) {
      throw const FormatException(
        'Costing snapshot does not belong to the Sale.',
      );
    }

    if (costing.request.saleId.trim() != request.saleId.trim()) {
      throw const FormatException(
        'Costing snapshot does not belong to the Sale.',
      );
    }

    if (costing.items.length != request.items.length) {
      throw const FormatException(
        'Every Sale Item must have exactly one cost snapshot.',
      );
    }

    for (final SalePostingItem item in request.items) {
      final SalePostingItemCostSnapshot itemCost = costing.itemCostFor(
        item.id,
      );

      itemCost.validate();

      if (itemCost.saleItemId.trim() != item.id.trim() ||
          itemCost.productId.trim() != item.productId.trim()) {
        throw const FormatException(
          'Cost snapshot does not match the Sale Item.',
        );
      }
    }
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
