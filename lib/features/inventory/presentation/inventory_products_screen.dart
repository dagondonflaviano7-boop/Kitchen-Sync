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

  Widget _summaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 145,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFDBE5DD),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183027),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64756B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(
          label: 'Total Products',
          count: _items.length,
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF365F91),
        ),
        _summaryCard(
          label: 'In Stock',
          count: _countStatus(
            InventoryStockStatus.inStock,
          ),
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2E6B4F),
        ),
        _summaryCard(
          label: 'Low Stock',
          count: _countStatus(
            InventoryStockStatus.lowStock,
          ),
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFB26A00),
        ),
        _summaryCard(
          label: 'Out of Stock',
          count: _countStatus(
            InventoryStockStatus.outOfStock,
          ),
          icon: Icons.remove_shopping_cart_outlined,
          color: const Color(0xFFB3261E),
        ),
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

  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final Widget search = TextField(
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

        final Widget filters = Wrap(
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
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              filters,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 16),
            filters,
          ],
        );
      },
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

  Widget _buildProductCards(
    List<InventoryProductView> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final InventoryProductView item = items[index];

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
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Mode: ${_modeLabel(product.inventoryMode)}',
                          ),
                          Text(
                            'On Hand: ${item.quantity.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Average Cost: '
                            '₱${item.averageCost.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Retail: '
                            '₱${item.product.retailPrice.toStringAsFixed(2)}',
                          ),
                        ],
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Products',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF183027),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Monitor Product availability '
                        'and store stock.',
                        style: TextStyle(
                          color: Color(0xFF64756B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Refresh Inventory',
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSummary(),
            const SizedBox(height: 18),
            _buildToolbar(),
            const SizedBox(height: 16),
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
                      : LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            if (constraints.maxWidth >=
                                AppConstants.tabletBreakpoint) {
                              return _buildWideTable(
                                filtered,
                              );
                            }

                            return _buildProductCards(
                              filtered,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
