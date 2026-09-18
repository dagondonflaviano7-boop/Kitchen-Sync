import 'package:kitchen_sync/domain/models/inventory_product_view.dart';
import 'package:sqflite/sqflite.dart';

class InventoryProductDao {
  const InventoryProductDao();

  Future<List<InventoryProductView>> findForStore(
    DatabaseExecutor database, {
    required String storeId,
  }) async {
    final String normalizedStoreId = storeId.trim();

    if (normalizedStoreId.isEmpty) {
      throw const FormatException(
        'Inventory Store ID is required.',
      );
    }

    final List<Map<String, Object?>> rows = await database.rawQuery(
      '''
      SELECT
        products.*,
        ? AS inventory_store_id,
        COALESCE(inventory.quantity, 0)
          AS inventory_quantity,
        COALESCE(inventory.average_cost, 0)
          AS inventory_average_cost,
        inventory.updated_at
          AS inventory_updated_at
      FROM products
      LEFT JOIN inventory
        ON inventory.product_id = products.id
        AND inventory.store_id = ?
      WHERE products.active = 1
        AND products.deleted_at IS NULL
      ORDER BY
        products.product_name COLLATE NOCASE,
        products.sku
      ''',
      <Object?>[
        normalizedStoreId,
        normalizedStoreId,
      ],
    );

    return rows.map(InventoryProductView.fromSqlite).toList(growable: false);
  }
}
