import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/product_repository.dart';
import 'package:kitchen_sync/data/repositories/recipe_repository.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/features/master_data/products/presentation/product_form_screen.dart';

enum ProductStatusFilter {
  all,
  active,
  inactive,
}

class ProductScreen extends StatefulWidget {
  const ProductScreen({
    super.key,
  });

  @override
  State<ProductScreen> createState() {
    return _ProductScreenState();
  }
}

class _ProductScreenState extends State<ProductScreen> {
  static const Color _surface = Color(0xFFF8F6F1);

  final ProductRepository _repository = const ProductRepository();

  final RecipeRepository _recipeRepository = const RecipeRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = <Product>[];
  List<Product> _filteredProducts = <Product>[];

  Map<String, Recipe> _recipesById = <String, Recipe>{};

  ProductStatusFilter _statusFilter = ProductStatusFilter.all;

  ProductInventoryMode? _inventoryModeFilter;

  bool _loading = true;
  bool _changingStatus = false;
  String? _errorMessage;

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _statusFilter != ProductStatusFilter.all ||
        _inventoryModeFilter != null;
  }

  @override
  void initState() {
    super.initState();

    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<Product> products = await _repository.getProducts(
        includeInactive: true,
      );

      final List<Recipe> recipes = await _recipeRepository.getRecipes();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _recipesById = <String, Recipe>{
          for (final Recipe recipe in recipes) recipe.id: recipe,
        };
        _loading = false;
      });

      _applyFilters();
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load Products: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load Products.';
      });
    }
  }

  Future<void> _openProductForm({
    Product? product,
  }) async {
    if (_loading || _changingStatus) {
      return;
    }

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (
          BuildContext routeContext,
        ) {
          return ProductFormScreen(
            product: product,
          );
        },
      ),
    );

    if (saved != true || !mounted) {
      return;
    }

    await _loadProducts();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            product == null
                ? 'Product created successfully.'
                : 'Product updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirmStatusChange(
    Product product,
  ) async {
    final bool targetActive = !product.active;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          icon: Icon(
            targetActive
                ? Icons.check_circle_outline
                : Icons.pause_circle_outline,
          ),
          title: Text(
            targetActive ? 'Activate Product?' : 'Deactivate Product?',
          ),
          content: Text(
            targetActive
                ? '${product.productName} will become '
                    'available for use.'
                : '${product.productName} will remain '
                    'available in history.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                targetActive ? 'Activate' : 'Deactivate',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _toggleActive(
    Product product,
  ) async {
    if (_changingStatus) {
      return;
    }

    final bool confirmed = await _confirmStatusChange(product);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _changingStatus = true;
    });

    try {
      await _repository.setProductActive(
        product.id,
        !product.active,
      );

      await _loadProducts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              product.active ? 'Product deactivated.' : 'Product activated.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on StateError catch (error) {
      _showActionError(error.message);
    } on FormatException catch (error) {
      _showActionError(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        'Product status update failed: '
        '$error\n$stackTrace',
      );

      _showActionError(
        'Unable to update Product status.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingStatus = false;
        });
      }
    }
  }

  void _showActionError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _applyFilters() {
    final String query = _searchController.text.trim().toLowerCase();

    final List<Product> filtered = _products.where(
      (Product product) {
        final String recipeName = _recipeName(product).toLowerCase();

        final bool matchesSearch = query.isEmpty ||
            product.sku.toLowerCase().contains(query) ||
            (product.barcode ?? '').toLowerCase().contains(query) ||
            product.productName.toLowerCase().contains(query) ||
            (product.brandName ?? '').toLowerCase().contains(query) ||
            recipeName.contains(query);

        final bool matchesStatus = switch (_statusFilter) {
          ProductStatusFilter.active => product.active,
          ProductStatusFilter.inactive => !product.active,
          ProductStatusFilter.all => true,
        };

        final bool matchesInventoryMode = _inventoryModeFilter == null ||
            product.inventoryMode == _inventoryModeFilter;

        return matchesSearch && matchesStatus && matchesInventoryMode;
      },
    ).toList(growable: false);

    filtered.sort(
      (
        Product first,
        Product second,
      ) {
        final int nameComparison = first.productName.toLowerCase().compareTo(
              second.productName.toLowerCase(),
            );

        if (nameComparison != 0) {
          return nameComparison;
        }

        return first.sku.compareTo(second.sku);
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = ProductStatusFilter.all;
      _inventoryModeFilter = null;
    });

    _applyFilters();
  }

  String _inventoryModeLabel(
    ProductInventoryMode mode,
  ) {
    switch (mode) {
      case ProductInventoryMode.direct:
        return 'DIRECT';
      case ProductInventoryMode.recipe:
        return 'RECIPE';
      case ProductInventoryMode.none:
        return 'NONE';
    }
  }

  String _costingMethodLabel(
    ProductCostingMethod method,
  ) {
    switch (method) {
      case ProductCostingMethod.manual:
        return 'MANUAL';
      case ProductCostingMethod.ingredient:
        return 'INGREDIENT';
      case ProductCostingMethod.hybrid:
        return 'HYBRID';
    }
  }

  String _recipeName(
    Product product,
  ) {
    final String recipeId = product.recipeId?.trim() ?? '';

    if (recipeId.isEmpty) {
      return 'No Recipe';
    }

    final Recipe? recipe = _recipesById[recipeId];

    if (recipe == null) {
      return 'Recipe unavailable';
    }

    return '${recipe.recipeCode} • '
        '${recipe.recipeName}';
  }

  Widget _buildStatusBadge(
    Product product,
  ) {
    final bool active = product.active;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF3) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFFABEFC6) : const Color(0xFFD0D5DD),
        ),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? const Color(0xFF067647) : const Color(0xFF475467),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInventoryBadge(
    Product product,
  ) {
    final Color color = switch (product.inventoryMode) {
      ProductInventoryMode.direct => const Color(0xFF175CD3),
      ProductInventoryMode.recipe => const Color(0xFF7C3AED),
      ProductInventoryMode.none => const Color(0xFF475467),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        _inventoryModeLabel(
          product.inventoryMode,
        ),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  PopupMenuButton<String> _buildActionsMenu(
    Product product,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Product actions',
      enabled: !_changingStatus,
      onSelected: (String value) {
        if (value == 'edit') {
          _openProductForm(
            product: product,
          );
        }

        if (value == 'toggle') {
          _toggleActive(product);
        }
      },
      itemBuilder: (
        BuildContext menuContext,
      ) {
        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined),
                SizedBox(width: 12),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  product.active
                      ? Icons.pause_circle_outline
                      : Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                Text(
                  product.active ? 'Deactivate' : 'Activate',
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (
                String value,
              ) {
                _applyFilters();
              },
              decoration: InputDecoration(
                labelText: 'Search Products',
                hintText: 'SKU, barcode, Product Name, '
                    'Brand, or Recipe',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<ProductStatusFilter>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<ProductStatusFilter>>[
                ButtonSegment<ProductStatusFilter>(
                  value: ProductStatusFilter.all,
                  label: Text('All'),
                ),
                ButtonSegment<ProductStatusFilter>(
                  value: ProductStatusFilter.active,
                  label: Text('Active'),
                ),
                ButtonSegment<ProductStatusFilter>(
                  value: ProductStatusFilter.inactive,
                  label: Text('Inactive'),
                ),
              ],
              selected: <ProductStatusFilter>{
                _statusFilter,
              },
              onSelectionChanged: (
                Set<ProductStatusFilter> selection,
              ) {
                setState(() {
                  _statusFilter = selection.first;
                });

                _applyFilters();
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ProductInventoryMode?>(
              initialValue: _inventoryModeFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Inventory Mode',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<ProductInventoryMode?>>[
                const DropdownMenuItem<ProductInventoryMode?>(
                  value: null,
                  child: Text(
                    'All Inventory Modes',
                  ),
                ),
                ...ProductInventoryMode.values.map(
                  (
                    ProductInventoryMode mode,
                  ) {
                    return DropdownMenuItem<ProductInventoryMode?>(
                      value: mode,
                      child: Text(
                        _inventoryModeLabel(mode),
                      ),
                    );
                  },
                ),
              ],
              onChanged: (
                ProductInventoryMode? value,
              ) {
                setState(() {
                  _inventoryModeFilter = value;
                });

                _applyFilters();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_filteredProducts.length} '
                    'of ${_products.length} Products',
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(
                      Icons.filter_alt_off,
                    ),
                    label: const Text(
                      'Clear Filters',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCards() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        88,
      ),
      itemCount: _filteredProducts.length,
      separatorBuilder: (
        BuildContext context,
        int index,
      ) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final Product product = _filteredProducts[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _changingStatus
                ? null
                : () {
                    _openProductForm(
                      product: product,
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFEDE9FE),
                        foregroundColor: const Color(0xFF6D28D9),
                        child: Text(
                          product.productName.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${product.sku}'
                              '${product.barcode == null ? '' : ' • ${product.barcode}'}',
                            ),
                          ],
                        ),
                      ),
                      _buildActionsMenu(product),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusBadge(product),
                      _buildInventoryBadge(product),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          _costingMethodLabel(
                            product.costingMethod,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (product.usesRecipeInventory)
                    Text(
                      'Recipe: ${_recipeName(product)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (product.usesRecipeInventory) const SizedBox(height: 10),
                  Wrap(
                    spacing: 22,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Cost: '
                        '₱${product.cost.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Retail: '
                        '₱${product.retailPrice.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Profit: '
                        '₱${product.grossProfit.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Margin: '
                        '${product.grossMargin.toStringAsFixed(2)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
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

    return Column(
      children: [
        _buildFilters(),
        const Divider(height: 1),
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    _hasActiveFilters
                        ? 'No Products match the '
                            'selected filters.'
                        : 'No Products have been '
                            'added yet.',
                    textAlign: TextAlign.center,
                  ),
                )
              : _buildProductCards(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Product Master'),
        actions: [
          IconButton(
            tooltip: 'Refresh Products',
            onPressed: _loading ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _changingStatus
            ? null
            : () {
                _openProductForm();
              },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
