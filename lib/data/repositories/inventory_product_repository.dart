import 'package:kitchen_sync/data/local/daos/inventory_product_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/inventory_product_view.dart';
import 'package:sqflite/sqflite.dart';

class InventoryProductRepository {
  final InventoryProductDao inventoryProductDao;

  const InventoryProductRepository({
    this.inventoryProductDao = const InventoryProductDao(),
  });

  Future<List<InventoryProductView>> getProducts({
    required String storeId,
  }) async {
    final String normalizedStoreId = storeId.trim();

    if (normalizedStoreId.isEmpty) {
      throw const FormatException(
        'Inventory Store ID is required.',
      );
    }

    final Database database = await AppDatabase.instance.database;

    return inventoryProductDao.findForStore(
      database,
      storeId: normalizedStoreId,
    );
  }
}
