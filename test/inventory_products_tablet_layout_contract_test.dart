import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String screen;

  setUpAll(() {
    final File file = File(
      'lib/features/inventory/presentation/'
      'inventory_products_screen.dart',
    );

    expect(
      file.existsSync(),
      isTrue,
      reason: 'Inventory Products Screen must exist.',
    );

    screen = file.readAsStringSync();
  });

  void containsAll(
    List<String> values,
  ) {
    for (final String value in values) {
      expect(
        screen,
        contains(value),
        reason: 'Expected tablet layout to contain $value.',
      );
    }
  }

  group('Inventory Products tablet layout', () {
    test('defines explicit responsive display modes', () {
      containsAll(<String>[
        'enum InventoryProductsLayoutMode',
        'phone',
        'tablet',
        'desktop',
        '_layoutMode(',
      ]);
    });

    test('uses width-based responsive breakpoints', () {
      containsAll(<String>[
        'constraints.maxWidth',
        'InventoryProductsLayoutMode.phone',
        'InventoryProductsLayoutMode.tablet',
        'InventoryProductsLayoutMode.desktop',
      ]);
    });

    test('defines responsive page padding', () {
      containsAll(<String>[
        '_pagePadding(',
        'EdgeInsets.symmetric(',
      ]);
    });

    test('shows compact summary cards in the header', () {
      containsAll(<String>[
        '_buildInventoryHeader',
        '_buildHeaderSummaryCards',
        'required bool compact',
        'height: compact ? 58 : 66',
      ]);
    });

    test('places tablet cards right of the title', () {
      containsAll(<String>[
        '_buildInventoryHeader(mode)',
        'child: _buildHeaderSummaryCards()',
        'InventoryProductsLayoutMode.tablet',
        'const SizedBox(width: 16)',
      ]);
    });

    test('keeps all four header cards in one row', () {
      containsAll(<String>[
        'for (',
        'index < cards.length;',
        'child: cards[index]',
        '_buildHeaderSummaryCards()',
      ]);
    });

    test('separates search and filters on tablet', () {
      containsAll(<String>[
        '_buildResponsiveToolbar',
        '_buildSearchField',
        '_buildStockFilters',
      ]);
    });

    test('uses cards for phone and tablet', () {
      containsAll(<String>[
        '_buildProductCards',
        'mode == InventoryProductsLayoutMode.desktop',
        ': _buildProductCards(',
      ]);
    });

    test('uses table only on desktop', () {
      containsAll(<String>[
        '_buildWideTable',
        'mode == InventoryProductsLayoutMode.desktop',
      ]);
    });

    test('provides tablet Product card', () {
      containsAll(<String>[
        '_buildTabletProductCard',
        'ProductThumbnail(',
        'item.product.imageUrl',
        'item.quantity',
        'item.averageCost',
        'item.product.retailPrice',
        'item.stockStatus',
      ]);
    });

    test('increases tablet Product image size', () {
      containsAll(<String>[
        'size: 88',
      ]);
    });

    test('provides tablet stock metric tiles', () {
      containsAll(<String>[
        '_buildMetricTile',
        "'On Hand'",
        "'Average Cost'",
        "'Retail Price'",
      ]);
    });

    test('preserves loading error and empty states', () {
      containsAll(<String>[
        'CircularProgressIndicator',
        "'Unable to load Inventory Products.'",
        "'No Inventory Products found.'",
        "'No Products match the selected filters.'",
      ]);
    });

    test('preserves search and stock filters', () {
      containsAll(<String>[
        "'Search Product, SKU, or barcode'",
        'InventoryStockFilter.all',
        'InventoryStockFilter.inStock',
        'InventoryStockFilter.lowStock',
        'InventoryStockFilter.outOfStock',
      ]);
    });

    test('preserves refresh behavior', () {
      containsAll(<String>[
        "'Refresh Inventory'",
        '_loadProducts',
      ]);
    });
    test('keeps tablet Search and filters on one row', () {
      containsAll(<String>[
        'if (mode == InventoryProductsLayoutMode.phone)',
        'alignment: Alignment.centerRight',
        'child: _buildStockFilters()',
        'const SizedBox(width: 12)',
      ]);
    });
  });
}
