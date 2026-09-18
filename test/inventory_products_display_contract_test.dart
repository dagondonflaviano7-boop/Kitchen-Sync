import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String screen;
  late String thumbnail;
  late String model;
  late String dao;
  late String repository;
  late String shell;

  setUpAll(() {
    final Map<String, File> files = <String, File>{
      'screen': File(
        'lib/features/inventory/presentation/'
        'inventory_products_screen.dart',
      ),
      'thumbnail': File(
        'lib/features/inventory/presentation/'
        'product_thumbnail.dart',
      ),
      'model': File(
        'lib/domain/models/inventory_product_view.dart',
      ),
      'dao': File(
        'lib/data/local/daos/inventory_product_dao.dart',
      ),
      'repository': File(
        'lib/data/repositories/'
        'inventory_product_repository.dart',
      ),
      'shell': File(
        'lib/features/dashboard/presentation/'
        'adaptive_shell.dart',
      ),
    };

    for (final MapEntry<String, File> entry in files.entries) {
      expect(
        entry.value.existsSync(),
        isTrue,
        reason: '${entry.key} implementation must exist.',
      );
    }

    screen = files['screen']!.readAsStringSync();
    thumbnail = files['thumbnail']!.readAsStringSync();
    model = files['model']!.readAsStringSync();
    dao = files['dao']!.readAsStringSync();
    repository = files['repository']!.readAsStringSync();
    shell = files['shell']!.readAsStringSync();
  });

  void containsAll(
    String source,
    List<String> values,
  ) {
    for (final String value in values) {
      expect(
        source,
        contains(value),
        reason: 'Expected implementation to contain $value.',
      );
    }
  }

  group('Inventory Products data contract', () {
    test('defines store-scoped Inventory Product view', () {
      containsAll(model, <String>[
        'class InventoryProductView',
        'final Product product',
        'final String storeId',
        'final double quantity',
        'final double averageCost',
        'final DateTime? inventoryUpdatedAt',
      ]);
    });

    test('defines stock status behavior', () {
      containsAll(model, <String>[
        'enum InventoryStockStatus',
        'inStock',
        'lowStock',
        'outOfStock',
        'InventoryStockStatus get stockStatus',
      ]);
    });

    test('joins active Products with store Inventory', () {
      containsAll(dao, <String>[
        'class InventoryProductDao',
        'Future<List<InventoryProductView>> findForStore(',
        'DatabaseExecutor database',
        'LEFT JOIN inventory',
        'inventory.product_id = products.id',
        'inventory.store_id = ?',
        'products.active = 1',
      ]);
    });

    test('returns zero balance when Inventory is absent', () {
      containsAll(dao, <String>[
        'COALESCE(inventory.quantity, 0)',
        'COALESCE(inventory.average_cost, 0)',
      ]);
    });

    test('provides Inventory Product repository', () {
      containsAll(repository, <String>[
        'class InventoryProductRepository',
        'InventoryProductDao inventoryProductDao',
        'Future<List<InventoryProductView>> getProducts(',
        'AppDatabase.instance.database',
        'inventoryProductDao.findForStore(',
      ]);
    });
  });

  group('Product Thumbnail contract', () {
    test('defines reusable Product thumbnail', () {
      containsAll(thumbnail, <String>[
        'class ProductThumbnail extends StatelessWidget',
        'final String? imageUrl',
        'final String productName',
        'final double size',
      ]);
    });

    test('renders saved Product picture', () {
      containsAll(thumbnail, <String>[
        'Image.network(',
        'imageUrl',
        'BoxFit.cover',
        'width: size',
        'height: size',
      ]);
    });

    test('handles image loading and failure', () {
      containsAll(thumbnail, <String>[
        'loadingBuilder:',
        'CircularProgressIndicator',
        'errorBuilder:',
        'Icons.inventory_2_outlined',
      ]);
    });

    test('supports missing image placeholder', () {
      containsAll(thumbnail, <String>[
        'trim().isEmpty',
        'Product image is unavailable',
        'Semantics(',
      ]);
    });
  });

  group('Inventory Products Screen contract', () {
    test('defines store-scoped responsive screen', () {
      containsAll(screen, <String>[
        'class InventoryProductsScreen extends StatefulWidget',
        'required this.storeId',
        'InventoryProductRepository',
        'LayoutBuilder',
        'AppConstants.tabletBreakpoint',
      ]);
    });

    test('loads Products and stock', () {
      containsAll(screen, <String>[
        '_repository.getProducts(',
        'storeId: widget.storeId',
        'CircularProgressIndicator',
        'Unable to load Inventory Products.',
        "'Retry'",
      ]);
    });

    test('shows summary cards', () {
      containsAll(screen, <String>[
        "'Total Products'",
        "'In Stock'",
        "'Low Stock'",
        "'Out of Stock'",
      ]);
    });

    test('supports search and stock filters', () {
      containsAll(screen, <String>[
        "'Search Product, SKU, or barcode'",
        'InventoryStockFilter',
        'product.productName',
        'product.sku',
        'product.barcode',
      ]);
    });

    test('shows Product pictures and stock fields', () {
      containsAll(screen, <String>[
        'ProductThumbnail(',
        'imageUrl: item.product.imageUrl',
        'item.quantity',
        'item.averageCost',
        'item.product.retailPrice',
        'item.stockStatus',
      ]);
    });

    test('provides wide table and narrow cards', () {
      containsAll(screen, <String>[
        'DataTable',
        'ListView.builder',
        '_buildWideTable',
        '_buildProductCards',
      ]);
    });

    test('provides refresh empty and filtered states', () {
      containsAll(screen, <String>[
        "'Refresh Inventory'",
        "'No Inventory Products found.'",
        "'No Products match the selected filters.'",
      ]);
    });
  });

  group('Adaptive Shell integration contract', () {
    test('imports Inventory Products Screen', () {
      expect(
        shell,
        contains(
          'package:kitchen_sync/features/inventory/'
          'presentation/inventory_products_screen.dart',
        ),
      );
    });

    test('replaces Inventory placeholder', () {
      containsAll(shell, <String>[
        'InventoryProductsScreen(',
        'storeId: widget.sessionContext.store.id',
      ]);

      expect(
        shell,
        isNot(
          contains(
            "title: 'Inventory',\n"
            '          icon: Icons.inventory_2,',
          ),
        ),
      );
    });

    test('preserves Inventory permission', () {
      containsAll(shell, <String>[
        "label: 'Inventory'",
        'permission: Permission.products',
      ]);
    });
  });
}
