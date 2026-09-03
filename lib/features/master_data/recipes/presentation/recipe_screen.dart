import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/recipe_repository.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/features/master_data/recipes/presentation/recipe_form_screen.dart';

enum RecipeStatusFilter {
  all,
  active,
  inactive,
}

class RecipeScreen extends StatefulWidget {
  final String currentUserId;

  const RecipeScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<RecipeScreen> createState() {
    return _RecipeScreenState();
  }
}

class _RecipeScreenState extends State<RecipeScreen> {
  final RecipeRepository _recipeRepository = const RecipeRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Recipe> _recipes = <Recipe>[];
  List<Recipe> _filteredRecipes = <Recipe>[];

  RecipeStatusFilter _statusFilter = RecipeStatusFilter.all;

  RecipeCategory? _categoryFilter;

  bool _loading = true;
  bool _changingStatus = false;
  bool _deleting = false;

  String? _errorMessage;

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _statusFilter != RecipeStatusFilter.all ||
        _categoryFilter != null;
  }

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<Recipe> recipes = await _recipeRepository.getRecipes();

      if (!mounted) {
        return;
      }

      setState(() {
        _recipes = recipes;
        _loading = false;
      });

      _applyFilters();
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load Recipes: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load Recipes.';
      });
    }
  }

  void _applyFilters() {
    final String query = _searchController.text.trim().toLowerCase();

    final List<Recipe> filtered = _recipes.where(
      (Recipe recipe) {
        final bool matchesSearch = query.isEmpty ||
            recipe.recipeCode.toLowerCase().contains(query) ||
            recipe.recipeName.toLowerCase().contains(query) ||
            _categoryLabel(
              recipe.category,
            ).toLowerCase().contains(query);

        final bool matchesStatus = switch (_statusFilter) {
          RecipeStatusFilter.all => true,
          RecipeStatusFilter.active => recipe.active,
          RecipeStatusFilter.inactive => !recipe.active,
        };

        final bool matchesCategory =
            _categoryFilter == null || recipe.category == _categoryFilter;

        return matchesSearch && matchesStatus && matchesCategory;
      },
    ).toList(growable: false);

    filtered.sort(
      (Recipe first, Recipe second) {
        final int byName = first.recipeName.toLowerCase().compareTo(
              second.recipeName.toLowerCase(),
            );

        if (byName != 0) {
          return byName;
        }

        return first.recipeCode.compareTo(
          second.recipeCode,
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredRecipes = filtered;
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = RecipeStatusFilter.all;
      _categoryFilter = null;
    });

    _applyFilters();
  }

  String _categoryLabel(
    RecipeCategory category,
  ) {
    return switch (category) {
      RecipeCategory.mainDish => 'Main Dish',
      RecipeCategory.sideDish => 'Side Dish',
      RecipeCategory.beverage => 'Beverage',
      RecipeCategory.dessert => 'Dessert',
      RecipeCategory.sauce => 'Sauce',
      RecipeCategory.ingredientPrep => 'Ingredient Preparation',
    };
  }

  String _formatQuantity(double value) {
    return value
        .toStringAsFixed(4)
        .replaceFirst(
          RegExp(r'0+$'),
          '',
        )
        .replaceFirst(
          RegExp(r'\.$'),
          '',
        );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openRecipeForm({
    Recipe? recipe,
  }) async {
    if (_loading || _changingStatus || _deleting) {
      return;
    }

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (
          BuildContext routeContext,
        ) {
          return RecipeFormScreen(
            recipe: recipe,
            currentUserId: widget.currentUserId,
          );
        },
      ),
    );

    if (saved != true || !mounted) {
      return;
    }

    await _loadRecipes();

    if (!mounted) {
      return;
    }

    _showMessage(
      recipe == null
          ? 'Recipe created successfully.'
          : 'Recipe updated successfully.',
    );
  }

  Future<bool> _confirmStatusChange(
    Recipe recipe,
  ) async {
    final bool targetActive = !recipe.active;

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
            targetActive ? 'Activate Recipe?' : 'Deactivate Recipe?',
          ),
          content: Text(
            targetActive
                ? '${recipe.recipeName} will '
                    'become available for use.'
                : '${recipe.recipeName} will '
                    'remain available in history.',
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

    return confirmed == true;
  }

  Future<void> _toggleActive(
    Recipe recipe,
  ) async {
    if (_changingStatus || _deleting) {
      return;
    }

    final String currentUserId = widget.currentUserId.trim();

    if (currentUserId.isEmpty) {
      _showMessage(
        'Authenticated user identity is required.',
      );
      return;
    }

    if (!await _confirmStatusChange(recipe)) {
      return;
    }

    setState(() {
      _changingStatus = true;
    });

    try {
      await _recipeRepository.updateRecipe(
        recipe.copyWith(
          active: !recipe.active,
        ),
        currentUserId: currentUserId,
      );

      await _loadRecipes();

      if (mounted) {
        _showMessage(
          recipe.active ? 'Recipe deactivated.' : 'Recipe activated.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to change Recipe status: '
        '$error\n$stackTrace',
      );

      if (mounted) {
        _showMessage(
          error.toString().replaceFirst(
                'Bad state: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _changingStatus = false;
        });
      }
    }
  }

  Future<bool> _confirmDelete(
    Recipe recipe,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_outline,
          ),
          title: const Text(
            'Delete Recipe?',
          ),
          content: Text(
            '${recipe.recipeCode} | '
            '${recipe.recipeName} will be '
            'removed from normal Recipe lists. '
            'The synchronization tombstone '
            'will be preserved.',
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
              child: const Text(
                'Delete Recipe',
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _deleteRecipe(
    Recipe recipe,
  ) async {
    if (_deleting || _changingStatus) {
      return;
    }

    final String currentUserId = widget.currentUserId.trim();

    if (currentUserId.isEmpty) {
      _showMessage(
        'Authenticated user identity is required.',
      );
      return;
    }

    if (!await _confirmDelete(recipe)) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await _recipeRepository.deleteRecipe(
        recipe,
        currentUserId: currentUserId,
      );

      await _loadRecipes();

      if (mounted) {
        _showMessage(
          'Recipe deleted successfully.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to delete Recipe: '
        '$error\n$stackTrace',
      );

      if (mounted) {
        _showMessage(
          error.toString().replaceFirst(
                'Bad state: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Master',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadRecipes,
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
            : () {
                _openRecipeForm();
              },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Recipe',
        ),
      ),
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
                onPressed: _loadRecipes,
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
                  labelText: 'Search Recipes',
                  hintText: 'Recipe Code, Name, or Category',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
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
                  child: SegmentedButton<RecipeStatusFilter>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<RecipeStatusFilter>(
                        value: RecipeStatusFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment<RecipeStatusFilter>(
                        value: RecipeStatusFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment<RecipeStatusFilter>(
                        value: RecipeStatusFilter.inactive,
                        label: Text('Inactive'),
                      ),
                    ],
                    selected: <RecipeStatusFilter>{
                      _statusFilter,
                    },
                    onSelectionChanged: (
                      Set<RecipeStatusFilter> selection,
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
              DropdownButtonFormField<RecipeCategory?>(
                initialValue: _categoryFilter,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(
                    Icons.category_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<RecipeCategory?>>[
                  const DropdownMenuItem<RecipeCategory?>(
                    value: null,
                    child: Text(
                      'All Categories',
                    ),
                  ),
                  ...RecipeCategory.values.map(
                    (
                      RecipeCategory category,
                    ) {
                      return DropdownMenuItem<RecipeCategory?>(
                        value: category,
                        child: Text(
                          _categoryLabel(
                            category,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                onChanged: (
                  RecipeCategory? value,
                ) {
                  setState(() {
                    _categoryFilter = value;
                  });

                  _applyFilters();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_filteredRecipes.length} '
                      'of ${_recipes.length} Recipes',
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
          child: _buildRecipeResults(),
        ),
      ],
    );
  }

  Widget _buildRecipeResults() {
    if (_filteredRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _hasActiveFilters
                ? 'No Recipes match the '
                    'selected filters.'
                : 'No Recipes have been '
                    'added yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        if (constraints.maxWidth >= 1000) {
          return _buildRecipeTable(
            _filteredRecipes,
          );
        }

        return _buildRecipeCards(
          _filteredRecipes,
        );
      },
    );
  }

  Widget _buildStatusBadge(
    Recipe recipe,
  ) {
    final bool active = recipe.active;

    final Color background =
        active ? const Color(0xFFE7F6EC) : const Color(0xFFF2F4F7);

    final Color border =
        active ? const Color(0xFFABEFC6) : const Color(0xFFD0D5DD);

    final Color foreground =
        active ? const Color(0xFF067647) : const Color(0xFF475467);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: border,
        ),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSyncBadge(
    Recipe recipe,
  ) {
    final String label;
    final Color background;
    final Color border;
    final Color foreground;
    final IconData icon;

    switch (recipe.syncStatus) {
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
        border: Border.all(
          color: border,
        ),
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
    Recipe recipe,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Recipe actions',
      enabled: !_changingStatus && !_deleting,
      onSelected: (String value) {
        if (value == 'edit') {
          _openRecipeForm(
            recipe: recipe,
          );
        }

        if (value == 'toggle') {
          _toggleActive(recipe);
        }

        if (value == 'delete') {
          _deleteRecipe(recipe);
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
                  recipe.active
                      ? Icons.pause_circle_outline
                      : Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                Text(
                  recipe.active ? 'Deactivate' : 'Activate',
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                SizedBox(width: 12),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildRecipeCards(
    List<Recipe> recipes,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        88,
      ),
      itemCount: recipes.length,
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
        final Recipe recipe = recipes[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _changingStatus || _deleting
                ? null
                : () {
                    _openRecipeForm(
                      recipe: recipe,
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        child: Text(
                          recipe.recipeName.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.recipeName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              recipe.recipeCode,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      _buildActionsMenu(recipe),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusBadge(recipe),
                      _buildSyncBadge(recipe),
                      Chip(
                        avatar: const Icon(
                          Icons.category_outlined,
                          size: 16,
                        ),
                        label: Text(
                          _categoryLabel(
                            recipe.category,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (
                      BuildContext context,
                      BoxConstraints constraints,
                    ) {
                      final bool veryCompact = constraints.maxWidth < 390;

                      final List<Widget> metrics = <Widget>[
                        _buildCardMetric(
                          icon: Icons.inventory_2_outlined,
                          label: 'Ingredient count',
                          value: '${recipe.ingredients.length}',
                        ),
                        _buildCardMetric(
                          icon: Icons.restaurant_outlined,
                          label: 'Yield',
                          value: '${_formatQuantity(recipe.yieldQuantity)} '
                              '${recipe.yieldUnitCode}',
                        ),
                        _buildCardMetric(
                          icon: Icons.receipt_long_outlined,
                          label: 'Total Recipe Cost',
                          value:
                              '₱${recipe.totalRecipeCost.toStringAsFixed(2)}',
                        ),
                        _buildCardMetric(
                          icon: Icons.calculate_outlined,
                          label: 'Cost per Serving',
                          value: '₱${recipe.costPerServing.toStringAsFixed(2)}',
                        ),
                      ];

                      if (veryCompact) {
                        return Column(
                          children: [
                            metrics[0],
                            const SizedBox(height: 10),
                            metrics[1],
                            const SizedBox(height: 10),
                            metrics[2],
                            const SizedBox(height: 10),
                            metrics[3],
                          ],
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: metrics.map(
                          (Widget metric) {
                            return SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: metric,
                            );
                          },
                        ).toList(
                          growable: false,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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

  Widget _buildRecipeTable(
    List<Recipe> recipes,
  ) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          88,
        ),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 82,
            columns: const [
              DataColumn(
                label: Text('Recipe'),
              ),
              DataColumn(
                label: Text('Category'),
              ),
              DataColumn(
                numeric: true,
                label: Text('Ingredient count'),
              ),
              DataColumn(
                label: Text('Yield'),
              ),
              DataColumn(
                numeric: true,
                label: Text('Total Recipe Cost'),
              ),
              DataColumn(
                numeric: true,
                label: Text('Cost per Serving'),
              ),
              DataColumn(
                label: Text('Status'),
              ),
              DataColumn(
                label: Text('Sync'),
              ),
              DataColumn(
                label: Text('Actions'),
              ),
            ],
            rows: recipes.map(
              (Recipe recipe) {
                return DataRow(
                  onSelectChanged: _changingStatus || _deleting
                      ? null
                      : (bool? selected) {
                          if (selected == true) {
                            _openRecipeForm(
                              recipe: recipe,
                            );
                          }
                        },
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.recipeName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              recipe.recipeCode,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _categoryLabel(
                          recipe.category,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${recipe.ingredients.length}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_formatQuantity(recipe.yieldQuantity)} '
                        '${recipe.yieldUnitCode}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '₱${recipe.totalRecipeCost.toStringAsFixed(2)}',
                      ),
                    ),
                    DataCell(
                      Text(
                        '₱${recipe.costPerServing.toStringAsFixed(2)}',
                      ),
                    ),
                    DataCell(
                      _buildStatusBadge(recipe),
                    ),
                    DataCell(
                      _buildSyncBadge(recipe),
                    ),
                    DataCell(
                      _buildActionsMenu(recipe),
                    ),
                  ],
                );
              },
            ).toList(growable: false),
          ),
        ),
      ),
    );
  }
}
