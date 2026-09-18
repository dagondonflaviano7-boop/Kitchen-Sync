import 'package:flutter/material.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/repositories/inventory_product_repository.dart';
import 'package:kitchen_sync/domain/models/inventory_product_view.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/features/inventory/presentation/product_thumbnail.dart';

enum InventoryStockFilter {
  all,
  inStock,
  lowStock,
  outOfStock,
}

enum InventoryProductsLayoutMode {
  phone,
  tablet,
  desktop,
}

class InventoryProductsScreen extends StatefulWidget {
  final String storeId;

  const InventoryProductsScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<InventoryProductsScreen> createState() {
    return _InventoryProductsScreenState();
  }
}

class _InventoryProductsScreenState extends State<InventoryProductsScreen> {
  final InventoryProductRepository _repository =
      const InventoryProductRepository();

  final TextEditingController _searchController = TextEditingController();

  List<InventoryProductView> _items = const <InventoryProductView>[];

  InventoryStockFilter _stockFilter = InventoryStockFilter.all;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilters);
    _loadProducts();
  }

  void _refreshFilters() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<InventoryProductView> products = await _repository.getProducts(
        storeId: widget.storeId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = products;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load Inventory Products: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load Inventory Products.';
      });
    }
  }

  List<InventoryProductView> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();

    return _items.where(
      (InventoryProductView item) {
        final Product product = item.product;

        final bool matchesSearch = query.isEmpty ||
            product.productName.toLowerCase().contains(query) ||
            product.sku.toLowerCase().contains(query) ||
            (product.barcode ?? '').toLowerCase().contains(query);

        final bool matchesStatus = switch (_stockFilter) {
          InventoryStockFilter.all => true,
          InventoryStockFilter.inStock =>
            item.stockStatus == InventoryStockStatus.inStock,
          InventoryStockFilter.lowStock =>
            item.stockStatus == InventoryStockStatus.lowStock,
          InventoryStockFilter.outOfStock =>
            item.stockStatus == InventoryStockStatus.outOfStock,
        };

        return matchesSearch && matchesStatus;
      },
    ).toList(growable: false);
  }

  int _countStatus(
    InventoryStockStatus status,
  ) {
    return _items.where(
      (InventoryProductView item) {
        return item.stockStatus == status;
      },
    ).length;
  }

  String _modeLabel(
    ProductInventoryMode mode,
  ) {
    return productInventoryModeToStorage(mode);
  }

  String _statusLabel(
    InventoryStockStatus status,
  ) {
    return switch (status) {
      InventoryStockStatus.inStock => 'In Stock',
      InventoryStockStatus.lowStock => 'Low Stock',
      InventoryStockStatus.outOfStock => 'Out of Stock',
    };
  }

  Color _statusColor(
    InventoryStockStatus status,
  ) {
    return switch (status) {
      InventoryStockStatus.inStock => const Color(0xFF2E6B4F),
      InventoryStockStatus.lowStock => const Color(0xFFB26A00),
      InventoryStockStatus.outOfStock => const Color(0xFFB3261E),
    };
  }

  Widget _statusBadge(
    InventoryStockStatus status,
  ) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InventoryProductsLayoutMode _layoutMode(
    double width,
  ) {
    if (width < AppConstants.tabletBreakpoint) {
      return InventoryProductsLayoutMode.phone;
    }

    if (width < 1100) {
      return InventoryProductsLayoutMode.tablet;
    }

    return InventoryProductsLayoutMode.desktop;
  }

  EdgeInsets _pagePadding(
    InventoryProductsLayoutMode mode,
  ) {
    return switch (mode) {
      InventoryProductsLayoutMode.phone => const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      InventoryProductsLayoutMode.tablet => const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      InventoryProductsLayoutMode.desktop => const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 22,
        ),
    };
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool compact,
  }) {
    return Container(
      height: compact ? 58 : 66,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFDBE5DD),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: color,
              size: compact ? 17 : 19,
            ),
          ),
          SizedBox(
            width: compact ? 8 : 10,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFF183027),
                    fontSize: compact ? 16 : 18,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF64756B),
                    fontSize: compact ? 9.5 : 10.5,
                    height: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _summaryCards({
    required bool compact,
  }) {
    return <Widget>[
      _summaryCard(
        label: 'Total Products',
        count: _items.length,
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF365F91),
        compact: compact,
      ),
      _summaryCard(
        label: 'In Stock',
        count: _countStatus(
          InventoryStockStatus.inStock,
        ),
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2E6B4F),
        compact: compact,
      ),
      _summaryCard(
        label: 'Low Stock',
        count: _countStatus(
          InventoryStockStatus.lowStock,
        ),
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFB26A00),
        compact: compact,
      ),
      _summaryCard(
        label: 'Out of Stock',
        count: _countStatus(
          InventoryStockStatus.outOfStock,
        ),
        icon: Icons.remove_shopping_cart_outlined,
        color: const Color(0xFFB3261E),
        compact: compact,
      ),
    ];
  }

  Widget _buildPhoneSummaryGrid() {
    final List<Widget> cards = _summaryCards(
      compact: false,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        return cards[index];
      },
    );
  }

  Widget _buildHeaderSummaryCards() {
    final List<Widget> cards = _summaryCards(
      compact: true,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int index = 0; index < cards.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: cards[index],
          ),
        ],
      ],
    );
  }

  Widget _buildInventoryHeader(
    InventoryProductsLayoutMode mode,
  ) {
    final Widget title = const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Products',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF183027),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Monitor Product availability and store stock.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF64756B),
          ),
        ),
      ],
    );

    final Widget refresh = IconButton.filledTonal(
      tooltip: 'Refresh Inventory',
      onPressed: _loadProducts,
      icon: const Icon(Icons.refresh),
    );

    if (mode == InventoryProductsLayoutMode.phone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: title,
              ),
              const SizedBox(width: 12),
              refresh,
            ],
          ),
          const SizedBox(height: 14),
          _buildPhoneSummaryGrid(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: mode == InventoryProductsLayoutMode.tablet ? 220 : 270,
          child: title,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHeaderSummaryCards(),
        ),
        const SizedBox(width: 12),
        refresh,
      ],
    );
  }

  Widget _filterButton(
    InventoryStockFilter filter,
    String label,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: _stockFilter == filter,
      onSelected: (_) {
        setState(() {
          _stockFilter = filter;
        });
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Product, SKU, or barcode',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear Search',
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close),
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildStockFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterButton(
            InventoryStockFilter.all,
            'All',
          ),
          _filterButton(
            InventoryStockFilter.inStock,
            'In Stock',
          ),
          _filterButton(
            InventoryStockFilter.lowStock,
            'Low Stock',
          ),
          _filterButton(
            InventoryStockFilter.outOfStock,
            'Out of Stock',
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveToolbar(
    InventoryProductsLayoutMode mode,
  ) {
    if (mode == InventoryProductsLayoutMode.phone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildStockFilters(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildSearchField(),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildStockFilters(),
          ),
        ),
      ],
    );
  }

  Widget _buildWideTable(
    List<InventoryProductView> items,
  ) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFF1F6F2),
          ),
          columns: const [
            DataColumn(label: Text('Picture')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Mode')),
            DataColumn(
              label: Text('On Hand'),
              numeric: true,
            ),
            DataColumn(
              label: Text('Average Cost'),
              numeric: true,
            ),
            DataColumn(
              label: Text('Retail'),
              numeric: true,
            ),
            DataColumn(label: Text('Status')),
          ],
          rows: items.map(
            (InventoryProductView item) {
              final Product product = item.product;

              return DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      child: ProductThumbnail(
                        imageUrl: item.product.imageUrl,
                        productName: product.productName,
                        size: 52,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${product.sku}'
                            '${product.barcode == null ? '' : ' • ${product.barcode}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64756B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _modeLabel(
                        product.inventoryMode,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.quantity.toStringAsFixed(2),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₱${item.averageCost.toStringAsFixed(2)}',
                    ),
                  ),
                  DataCell(
                    Text(
                      '₱${item.product.retailPrice.toStringAsFixed(2)}',
                    ),
                  ),
                  DataCell(
                    _statusBadge(item.stockStatus),
                  ),
                ],
              );
            },
          ).toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE1E9E3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF2E6B4F),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64756B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF183027),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletProductCard(
    InventoryProductView item,
  ) {
    final Product product = item.product;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFDBE5DD),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(
                  imageUrl: item.product.imageUrl,
                  productName: product.productName,
                  size: 88,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF183027),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _statusBadge(
                            item.stockStatus,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${product.sku}'
                        '${product.barcode == null ? '' : ' • ${product.barcode}'}',
                        style: const TextStyle(
                          color: Color(0xFF64756B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Chip(
                        avatar: const Icon(
                          Icons.tune,
                          size: 16,
                        ),
                        label: Text(
                          _modeLabel(
                            product.inventoryMode,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.15,
              children: [
                _buildMetricTile(
                  label: 'On Hand',
                  value: item.quantity.toStringAsFixed(2),
                  icon: Icons.inventory_2_outlined,
                ),
                _buildMetricTile(
                  label: 'Average Cost',
                  value: '₱${item.averageCost.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                ),
                _buildMetricTile(
                  label: 'Retail Price',
                  value: '₱${item.product.retailPrice.toStringAsFixed(2)}',
                  icon: Icons.sell_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneProductCard(
    InventoryProductView item,
  ) {
    final Product product = item.product;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumbnail(
              imageUrl: item.product.imageUrl,
              productName: product.productName,
              size: 76,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.sku}'
                    '${product.barcode == null ? '' : ' • ${product.barcode}'}',
                    style: const TextStyle(
                      color: Color(0xFF64756B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mode: ${_modeLabel(product.inventoryMode)}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'On Hand: ${item.quantity.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Average Cost: '
                    '₱${item.averageCost.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Retail: '
                    '₱${item.product.retailPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  _statusBadge(item.stockStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCards(
    List<InventoryProductView> items,
    InventoryProductsLayoutMode mode,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final InventoryProductView item = items[index];

        if (mode == InventoryProductsLayoutMode.tablet) {
          return _buildTabletProductCard(item);
        }

        return _buildPhoneProductCard(item);
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: Color(0xFF2E6B4F),
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Unable to load Inventory Products.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilters)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    final List<InventoryProductView> filtered = _filteredItems;

    final bool hasFilters = _searchController.text.trim().isNotEmpty ||
        _stockFilter != InventoryStockFilter.all;

    return ColoredBox(
      color: const Color(0xFFF7F9F7),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final InventoryProductsLayoutMode mode =
              _layoutMode(constraints.maxWidth);

          return Padding(
            padding: _pagePadding(mode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInventoryHeader(mode),
                const SizedBox(height: 16),
                _buildResponsiveToolbar(mode),
                const SizedBox(height: 14),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text(
                            'No Inventory Products found.',
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                hasFilters
                                    ? 'No Products match the selected filters.'
                                    : 'No Inventory Products found.',
                              ),
                            )
                          : mode == InventoryProductsLayoutMode.desktop
                              ? _buildWideTable(
                                  filtered,
                                )
                              : _buildProductCards(
                                  filtered,
                                  mode,
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
