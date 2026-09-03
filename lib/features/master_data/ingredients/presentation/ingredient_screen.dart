import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/ingredient_repository.dart';
import 'package:kitchen_sync/data/services/master_data_auto_sync.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/features/master_data/ingredients/presentation/ingredient_form_screen.dart';

enum IngredientStatusFilter {
  all,
  active,
  inactive,
}

class IngredientScreen extends StatefulWidget {
  final String? currentUserId;

  const IngredientScreen({
    super.key,
    this.currentUserId,
  });

  @override
  State<IngredientScreen> createState() {
    return _IngredientScreenState();
  }
}

class _IngredientScreenState extends State<IngredientScreen> {
  static const Color _surface = Color(0xFFF8F6F1);

  final IngredientRepository _repository = const IngredientRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Ingredient> _ingredients = <Ingredient>[];

  List<Ingredient> _filteredIngredients = <Ingredient>[];

  IngredientStatusFilter _statusFilter = IngredientStatusFilter.all;

  IngredientCategory? _categoryFilter;
  String? _supplierFilter;

  bool _loading = true;
  bool _changingStatus = false;
  bool _deleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<Ingredient> ingredients = await _repository.getIngredients(
        includeInactive: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ingredients = ingredients;
        _loading = false;
      });

      _applyFilters();
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load Ingredients: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load Ingredients.';
      });
    }
  }

  Future<void> _openIngredientForm({
    Ingredient? ingredient,
  }) async {
    if (_loading || _changingStatus || _deleting) {
      return;
    }

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (
          BuildContext routeContext,
        ) {
          return IngredientFormScreen(
            ingredient: ingredient,
            currentUserId: widget.currentUserId?.trim() ?? '',
          );
        },
      ),
    );

    if (saved != true || !mounted) {
      return;
    }

    await _loadIngredients();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ingredient == null
                ? 'Ingredient created successfully.'
                : 'Ingredient updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirmStatusChange(
    Ingredient ingredient,
  ) async {
    final bool targetActive = !ingredient.active;

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
            targetActive ? 'Activate Ingredient?' : 'Deactivate Ingredient?',
          ),
          content: Text(
            targetActive
                ? '${ingredient.ingredientName} '
                    'will become available for use.'
                : '${ingredient.ingredientName} '
                    'will remain available in history.',
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
    Ingredient ingredient,
  ) async {
    if (_changingStatus || _deleting) {
      return;
    }

    final String currentUserId = widget.currentUserId?.trim() ?? '';

    if (currentUserId.isEmpty) {
      _showActionError(
        'Authenticated user identity is required.',
      );
      return;
    }

    final bool confirmed = await _confirmStatusChange(
      ingredient,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _changingStatus = true;
    });

    try {
      await _repository.setIngredientActive(
        ingredient.id,
        !ingredient.active,
        currentUserId: currentUserId,
      );

      unawaited(
        MasterDataAutoSync.instance.trigger(
          reason: MasterDataAutoSyncReason.ingredientStatusChanged,
        ),
      );

      await _loadIngredients();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              ingredient.active
                  ? 'Ingredient deactivated successfully.'
                  : 'Ingredient activated successfully.',
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
        'Ingredient status change failed: '
        '$error\n$stackTrace',
      );

      _showActionError(
        'Unable to update Ingredient status.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingStatus = false;
        });
      }
    }
  }

  Future<bool> _confirmDeleteIngredient(
    Ingredient ingredient,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_forever_outlined,
            color: Color(0xFFB42318),
            size: 34,
          ),
          title: const Text(
            'Delete Ingredient?',
          ),
          content: Text(
            '${ingredient.ingredientName} will be '
            'soft-deleted. Referenced Ingredients '
            'must be deactivated instead.',
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteIngredient(
    Ingredient ingredient,
  ) async {
    if (_deleting || _changingStatus) {
      return;
    }

    final String currentUserId = widget.currentUserId?.trim() ?? '';

    if (currentUserId.isEmpty) {
      _showActionError(
        'Authenticated user identity is required.',
      );
      return;
    }

    final bool confirmed = await _confirmDeleteIngredient(
      ingredient,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await _repository.deleteIngredient(
        ingredient,
        currentUserId: currentUserId,
      );

      unawaited(
        MasterDataAutoSync.instance.trigger(
          reason: MasterDataAutoSyncReason.ingredientDeleted,
        ),
      );

      await _loadIngredients();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${ingredient.ingredientName} '
              'deleted successfully.',
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
        'Ingredient delete failed: '
        '$error\n$stackTrace',
      );

      _showActionError(
        'Unable to delete the Ingredient.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  void _showActionError(String message) {
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
          duration: const Duration(
            seconds: 5,
          ),
        ),
      );
  }

  void _applyFilters() {
    final String query = _searchController.text.trim().toLowerCase();

    final List<Ingredient> filtered = _ingredients.where(
      (Ingredient ingredient) {
        final String categoryLabel = ingredientCategoryLabel(
          ingredient.category,
        ).toLowerCase();

        final bool matchesSearch = query.isEmpty ||
            ingredient.ingredientSku.toLowerCase().contains(query) ||
            ingredient.ingredientName.toLowerCase().contains(query) ||
            categoryLabel.contains(query) ||
            (ingredient.supplierNameSnapshot ?? '')
                .toLowerCase()
                .contains(query) ||
            ingredient.usageUnitCode.toLowerCase().contains(query) ||
            (ingredient.purchaseUnitCode ?? '').toLowerCase().contains(query);

        final bool matchesStatus = switch (_statusFilter) {
          IngredientStatusFilter.active => ingredient.active,
          IngredientStatusFilter.inactive => !ingredient.active,
          IngredientStatusFilter.all => true,
        };

        final bool matchesCategory =
            _categoryFilter == null || ingredient.category == _categoryFilter;

        final bool matchesSupplier = _supplierFilter == null ||
            ingredient.primarySupplierId == _supplierFilter;

        return matchesSearch &&
            matchesStatus &&
            matchesCategory &&
            matchesSupplier;
      },
    ).toList(growable: false);

    filtered.sort(
      (
        Ingredient first,
        Ingredient second,
      ) {
        final int nameComparison = first.ingredientName.toLowerCase().compareTo(
              second.ingredientName.toLowerCase(),
            );

        if (nameComparison != 0) {
          return nameComparison;
        }

        return first.ingredientSku.compareTo(
          second.ingredientSku,
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredIngredients = filtered;
    });
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _statusFilter != IngredientStatusFilter.all ||
        _categoryFilter != null ||
        _supplierFilter != null;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = IngredientStatusFilter.all;
      _categoryFilter = null;
      _supplierFilter = null;
    });

    _applyFilters();
  }

  Map<String, String> get _supplierOptions {
    final Map<String, String> suppliers = <String, String>{};

    for (final Ingredient ingredient in _ingredients) {
      final String? supplierId = ingredient.primarySupplierId;

      final String? supplierName = ingredient.supplierNameSnapshot;

      if (supplierId != null &&
          supplierId.trim().isNotEmpty &&
          supplierName != null &&
          supplierName.trim().isNotEmpty) {
        suppliers[supplierId] = supplierName;
      }
    }

    return suppliers;
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
        title: const Text(
          'Ingredient Master',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadIngredients,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _changingStatus || _deleting
            ? null
            : () => _openIngredientForm(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Ingredient',
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    Ingredient ingredient,
  ) {
    final bool active = ingredient.active;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F6EC) : const Color(0xFFF2F4F7),
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

  Widget _buildSyncBadge(
    Ingredient ingredient,
  ) {
    final String label;
    final Color background;
    final Color border;
    final Color foreground;
    final IconData icon;

    switch (ingredient.syncStatus) {
      case MasterSyncStatus.pending:
        label = 'Pending';
        background = const Color(0xFFFFFAEB);
        border = const Color(0xFFFED671);
        foreground = const Color(0xFFB54708);
        icon = Icons.schedule_outlined;
      case MasterSyncStatus.syncing:
        label = 'Syncing';
        background = const Color(0xFFEFF8FF);
        border = const Color(0xFFB2DDFF);
        foreground = const Color(0xFF175CD3);
        icon = Icons.sync;
      case MasterSyncStatus.synced:
        label = 'Synced';
        background = const Color(0xFFECFDF3);
        border = const Color(0xFFABEFC6);
        foreground = const Color(0xFF067647);
        icon = Icons.cloud_done_outlined;
      case MasterSyncStatus.error:
        label = 'Error';
        background = const Color(0xFFFEF3F2);
        border = const Color(0xFFFECDCA);
        foreground = const Color(0xFFB42318);
        icon = Icons.cloud_off_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuButton<String> _buildActionsMenu(
    Ingredient ingredient,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Ingredient actions',
      enabled: !_changingStatus && !_deleting,
      onSelected: (String value) {
        if (value == 'edit') {
          _openIngredientForm(
            ingredient: ingredient,
          );
        }

        if (value == 'toggle') {
          _toggleActive(ingredient);
        }

        if (value == 'delete') {
          _deleteIngredient(ingredient);
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
                  ingredient.active
                      ? Icons.pause_circle_outline
                      : Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                Text(
                  ingredient.active ? 'Deactivate' : 'Activate',
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: Color(0xFFB42318),
                ),
                SizedBox(width: 12),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Color(0xFFB42318),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildIngredientTable(
    List<Ingredient> ingredients,
  ) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          88,
        ),
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll<Color>(
            const Color(0xFFF2F4F7),
          ),
          columns: const [
            DataColumn(label: Text('SKU')),
            DataColumn(
              label: Text('Ingredient Name'),
            ),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Supplier')),
            DataColumn(label: Text('Purchase Unit')),
            DataColumn(label: Text('Usage Unit')),
            DataColumn(
              numeric: true,
              label: Text('Conversion'),
            ),
            DataColumn(
              numeric: true,
              label: Text('Purchase Cost'),
            ),
            DataColumn(
              numeric: true,
              label: Text('Cost / Usage Unit'),
            ),
            DataColumn(
              numeric: true,
              label: Text('Reorder'),
            ),
            DataColumn(
              numeric: true,
              label: Text('Par'),
            ),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Sync')),
            DataColumn(label: Text('Actions')),
          ],
          rows: ingredients.map(
            (Ingredient ingredient) {
              return DataRow(
                cells: [
                  DataCell(
                    SelectableText(
                      ingredient.ingredientSku,
                    ),
                  ),
                  DataCell(
                    Text(
                      ingredient.ingredientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      ingredientCategoryLabel(
                        ingredient.category,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      ingredient.supplierNameSnapshot ?? 'No Supplier',
                    ),
                  ),
                  DataCell(
                    Text(
                      ingredient.purchaseUnitCode ?? '-',
                    ),
                  ),
                  DataCell(
                    Text(
                      ingredient.usageUnitCode,
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatTableNumber(
                        ingredient.conversionFactor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₱${ingredient.latestPurchaseCost.toStringAsFixed(2)}',
                    ),
                  ),
                  DataCell(
                    Text(
                      '₱${ingredient.costPerUsageUnit.toStringAsFixed(4)}',
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatTableNumber(
                        ingredient.reorderLevel,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      ingredient.parLevel == null
                          ? '-'
                          : _formatTableNumber(
                              ingredient.parLevel!,
                            ),
                    ),
                  ),
                  DataCell(
                    _buildStatusBadge(ingredient),
                  ),
                  DataCell(
                    _buildSyncBadge(ingredient),
                  ),
                  DataCell(
                    _buildActionsMenu(ingredient),
                  ),
                ],
              );
            },
          ).toList(growable: false),
        ),
      ),
    );
  }

  String _formatTableNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadIngredients,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, String> suppliers = _supplierOptions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            8,
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Ingredients',
                  hintText: 'SKU, name, Category, Supplier, or Unit',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear Search',
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                          icon: const Icon(
                            Icons.clear,
                          ),
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<IngredientStatusFilter>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<IngredientStatusFilter>(
                        value: IngredientStatusFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment<IngredientStatusFilter>(
                        value: IngredientStatusFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment<IngredientStatusFilter>(
                        value: IngredientStatusFilter.inactive,
                        label: Text('Inactive'),
                      ),
                    ],
                    selected: <IngredientStatusFilter>{
                      _statusFilter,
                    },
                    onSelectionChanged: (
                      Set<IngredientStatusFilter> selection,
                    ) {
                      setState(() {
                        _statusFilter = selection.first;
                      });

                      _applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                ) {
                  final bool wide = constraints.maxWidth >= 620;

                  final List<Widget> filters = <Widget>[
                    DropdownButtonFormField<IngredientCategory?>(
                      initialValue: _categoryFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: <DropdownMenuItem<IngredientCategory?>>[
                        const DropdownMenuItem<IngredientCategory?>(
                          value: null,
                          child: Text(
                            'All Categories',
                          ),
                        ),
                        ...IngredientCategory.values.map(
                          (
                            IngredientCategory category,
                          ) {
                            return DropdownMenuItem<IngredientCategory?>(
                              value: category,
                              child: Text(
                                ingredientCategoryLabel(
                                  category,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: (
                        IngredientCategory? value,
                      ) {
                        setState(() {
                          _categoryFilter = value;
                        });

                        _applyFilters();
                      },
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: _supplierFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Supplier',
                        border: OutlineInputBorder(),
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Suppliers',
                          ),
                        ),
                        ...suppliers.entries.map(
                          (
                            MapEntry<String, String> entry,
                          ) {
                            return DropdownMenuItem<String?>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _supplierFilter = value;
                        });

                        _applyFilters();
                      },
                    ),
                  ];

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(
                          child: filters.first,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: filters.last,
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      filters.first,
                      const SizedBox(height: 12),
                      filters.last,
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_filteredIngredients.length} '
                      'of ${_ingredients.length} '
                      'Ingredients',
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
        const Divider(height: 1),
        Expanded(
          child: _filteredIngredients.isEmpty
              ? Center(
                  child: Text(
                    _hasActiveFilters
                        ? 'No Ingredients match '
                            'the selected filters.'
                        : 'No Ingredients have '
                            'been added yet.',
                    textAlign: TextAlign.center,
                  ),
                )
              : LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    if (constraints.maxWidth >= 900) {
                      return _buildIngredientTable(
                        _filteredIngredients,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        88,
                      ),
                      itemCount: _filteredIngredients.length,
                      separatorBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        return const SizedBox(
                          height: 10,
                        );
                      },
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        final Ingredient ingredient =
                            _filteredIngredients[index];

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                ingredient.ingredientName
                                    .substring(0, 1)
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              ingredient.ingredientName,
                            ),
                            subtitle: Text(
                              '${ingredient.ingredientSku} | '
                              '${ingredientCategoryLabel(ingredient.category)}\n'
                              '${ingredient.supplierNameSnapshot ?? 'No Supplier'} | '
                              '${ingredient.purchaseUnitCode ?? '-'} '
                              'to ${ingredient.usageUnitCode}\n'
                              '${ingredient.active ? 'Active' : 'Inactive'} | '
                              '₱${ingredient.costPerUsageUnit.toStringAsFixed(4)} '
                              'per ${ingredient.usageUnitCode}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Ingredient actions',
                              onSelected: (String value) {
                                if (value == 'edit') {
                                  _openIngredientForm(
                                    ingredient: ingredient,
                                  );
                                }

                                if (value == 'toggle') {
                                  _toggleActive(
                                    ingredient,
                                  );
                                }

                                if (value == 'delete') {
                                  _deleteIngredient(
                                    ingredient,
                                  );
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
                                          ingredient.active
                                              ? Icons.pause_circle_outline
                                              : Icons.check_circle_outline,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          ingredient.active
                                              ? 'Deactivate'
                                              : 'Activate',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFB42318),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Color(0xFFB42318),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
