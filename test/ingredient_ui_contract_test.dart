import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/ingredients/'
      'presentation/ingredient_screen.dart',
    ).readAsStringSync();
  });

  group('Ingredient screen foundation', () {
    test('provides Ingredient Master screen', () {
      expect(
        source,
        contains('class IngredientScreen'),
      );

      expect(
        source,
        contains("'Ingredient Master'"),
      );
    });

    test('receives current authenticated user', () {
      expect(
        source,
        contains('final String? currentUserId'),
      );

      expect(
        source,
        contains(
          'widget.currentUserId?.trim()',
        ),
      );
    });

    test('loads Ingredients through Repository', () {
      expect(
        source,
        contains('IngredientRepository'),
      );

      expect(
        source,
        contains(
          '_repository.getIngredients(',
        ),
      );

      expect(
        source,
        contains(
          'includeInactive: true',
        ),
      );
    });

    test('provides Loading, Error, and Retry states', () {
      expect(
        source,
        contains('CircularProgressIndicator'),
      );

      expect(
        source,
        contains(
          'Unable to load Ingredients.',
        ),
      );

      expect(
        source,
        contains("'Retry'"),
      );
    });
  });

  group('Ingredient search and filters', () {
    test('provides Ingredient search', () {
      expect(
        source,
        contains("'Search Ingredients'"),
      );

      expect(
        source,
        contains('_searchController'),
      );

      expect(
        source,
        contains('void _applyFilters()'),
      );
    });

    test('searches required Ingredient fields', () {
      expect(
        source,
        contains('ingredient.ingredientSku'),
      );

      expect(
        source,
        contains('ingredient.ingredientName'),
      );

      expect(
        source,
        contains(
          'ingredientCategoryLabel(',
        ),
      );

      expect(
        source,
        contains(
          'ingredient.supplierNameSnapshot',
        ),
      );

      expect(
        source,
        contains(
          'ingredient.usageUnitCode',
        ),
      );

      expect(
        source,
        contains(
          'ingredient.purchaseUnitCode',
        ),
      );
    });

    test('provides status filters', () {
      expect(
        source,
        contains(
          'enum IngredientStatusFilter',
        ),
      );

      expect(
        source,
        contains(
          'IngredientStatusFilter.all',
        ),
      );

      expect(
        source,
        contains(
          'IngredientStatusFilter.active',
        ),
      );

      expect(
        source,
        contains(
          'IngredientStatusFilter.inactive',
        ),
      );

      expect(
        source,
        contains(
          'SegmentedButton<IngredientStatusFilter>',
        ),
      );
    });

    test('provides Category filter', () {
      expect(
        source,
        contains(
          'IngredientCategory? _categoryFilter',
        ),
      );

      expect(
        source,
        contains("'All Categories'"),
      );

      expect(
        source,
        contains(
          'IngredientCategory.values.map',
        ),
      );
    });

    test('provides Supplier filter', () {
      expect(
        source,
        contains(
          'String? _supplierFilter',
        ),
      );

      expect(
        source,
        contains("'All Suppliers'"),
      );

      expect(
        source,
        contains(
          'Map<String, String> get _supplierOptions',
        ),
      );
    });

    test('provides Clear Filters', () {
      expect(
        source,
        contains('void _clearFilters()'),
      );

      expect(
        source,
        contains("'Clear Filters'"),
      );
    });

    test('reapplies filters after loading', () {
      final int assignment = source.indexOf('_ingredients = ingredients;');

      final int filterCall = source.indexOf(
        '_applyFilters();',
        assignment,
      );

      expect(assignment, greaterThanOrEqualTo(0));
      expect(filterCall, greaterThan(assignment));

      expect(
        source,
        isNot(
          contains(
            '_filteredIngredients = '
            'List<Ingredient>.from',
          ),
        ),
      );
    });

    test('provides separate empty states', () {
      expect(
        source,
        contains(
          'No Ingredients match ',
        ),
      );

      expect(
        source,
        contains(
          'the selected filters.',
        ),
      );

      expect(
        source,
        contains(
          'No Ingredients have ',
        ),
      );

      expect(
        source,
        contains(
          'been added yet.',
        ),
      );
    });
  });

  group('Ingredient navigation', () {
    test('provides Add Ingredient action', () {
      expect(
        source,
        contains("'Add Ingredient'"),
      );

      expect(
        source,
        contains(
          '() => _openIngredientForm()',
        ),
      );
    });

    test('opens Ingredient form for Add and Edit', () {
      expect(
        source,
        contains(
          'Future<void> _openIngredientForm(',
        ),
      );

      expect(
        source,
        contains('IngredientFormScreen('),
      );

      expect(
        source,
        contains(
          'ingredient: ingredient',
        ),
      );

      expect(
        source,
        contains(
          'currentUserId:',
        ),
      );
    });

    test('reloads list after saved change', () {
      expect(
        source,
        contains(
          'if (saved != true || !mounted)',
        ),
      );

      expect(
        source,
        contains(
          'await _loadIngredients()',
        ),
      );
    });
  });

  group('Ingredient status actions', () {
    test('provides status confirmation', () {
      expect(
        source,
        contains(
          '_confirmStatusChange(',
        ),
      );

      expect(
        source,
        contains("'Activate Ingredient?'"),
      );

      expect(
        source,
        contains("'Deactivate Ingredient?'"),
      );
    });

    test('changes status through Repository', () {
      expect(
        source,
        contains(
          '_repository.setIngredientActive(',
        ),
      );

      expect(
        source,
        contains(
          'currentUserId: currentUserId',
        ),
      );
    });

    test('triggers Ingredient status sync', () {
      expect(
        source,
        contains(
          'MasterDataAutoSyncReason'
          '.ingredientStatusChanged',
        ),
      );
    });
  });

  group('Ingredient deletion actions', () {
    test('provides delete confirmation', () {
      expect(
        source,
        contains(
          '_confirmDeleteIngredient(',
        ),
      );

      expect(
        source,
        contains("'Delete Ingredient?'"),
      );

      expect(
        source,
        contains(
          'must be deactivated instead.',
        ),
      );
    });

    test('uses Repository soft deletion', () {
      expect(
        source,
        contains(
          '_repository.deleteIngredient(',
        ),
      );

      expect(
        source,
        isNot(
          contains('database.delete('),
        ),
      );
    });

    test('triggers Ingredient deletion sync', () {
      expect(
        source,
        contains(
          'MasterDataAutoSyncReason'
          '.ingredientDeleted',
        ),
      );
    });

    test('displays Repository deletion errors', () {
      expect(
        source,
        contains('on StateError catch'),
      );

      expect(
        source,
        contains('_showActionError('),
      );
    });
  });

  group('Responsive Ingredient presentation', () {
    test('provides mobile Ingredient cards', () {
      expect(
        source,
        contains('ListView.separated('),
      );

      expect(
        source,
        contains('return Card('),
      );

      expect(
        source,
        contains('ListTile('),
      );
    });

    test('provides mobile actions menu', () {
      expect(
        source,
        contains(
          "tooltip: 'Ingredient actions'",
        ),
      );

      expect(
        source,
        contains("'Edit'"),
      );

      expect(
        source,
        contains("'Activate'"),
      );

      expect(
        source,
        contains("'Deactivate'"),
      );

      expect(
        source,
        contains("'Delete'"),
      );
    });

    test('provides Desktop and Web table', () {
      expect(
        source,
        contains(
          'Widget _buildIngredientTable(',
        ),
      );

      expect(
        source,
        contains('DataTable('),
      );

      expect(
        source,
        contains(
          'constraints.maxWidth >= 900',
        ),
      );
    });

    test('provides important table columns', () {
      for (final String column in <String>[
        'SKU',
        'Ingredient Name',
        'Category',
        'Supplier',
        'Purchase Unit',
        'Usage Unit',
        'Conversion',
        'Purchase Cost',
        'Cost / Usage Unit',
        'Reorder',
        'Par',
        'Status',
        'Sync',
        'Actions',
      ]) {
        expect(
          source,
          contains("Text('$column')"),
        );
      }
    });

    test('displays cost per Usage Unit', () {
      expect(
        source,
        contains(
          'ingredient.costPerUsageUnit',
        ),
      );

      expect(
        source,
        contains(
          'toStringAsFixed(4)',
        ),
      );
    });
  });

  group('Ingredient status and Sync badges', () {
    test('provides Active and Inactive badges', () {
      expect(
        source,
        contains(
          'Widget _buildStatusBadge(',
        ),
      );

      expect(
        source,
        contains(
          "active ? 'Active' : 'Inactive'",
        ),
      );
    });

    test('provides Sync status badge', () {
      expect(
        source,
        contains(
          'Widget _buildSyncBadge(',
        ),
      );

      expect(
        source,
        contains(
          'switch (ingredient.syncStatus)',
        ),
      );
    });

    test('supports every Sync state', () {
      expect(
        source,
        contains(
          'MasterSyncStatus.pending',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.syncing',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.synced',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.error',
        ),
      );

      expect(source, contains("'Pending'"));
      expect(source, contains("'Syncing'"));
      expect(source, contains("'Synced'"));
      expect(source, contains("'Error'"));
    });
  });

  group('Ingredient stock isolation', () {
    test('does not update Ingredient Inventory', () {
      expect(
        source,
        isNot(contains('ingredient_inventory')),
      );
    });

    test('does not create Ingredient movements', () {
      expect(
        source,
        isNot(contains('ingredient_movements')),
      );
    });
  });
}
