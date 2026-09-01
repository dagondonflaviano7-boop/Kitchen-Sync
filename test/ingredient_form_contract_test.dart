import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/ingredients/'
      'presentation/ingredient_form_screen.dart',
    ).readAsStringSync();
  });

  group('Ingredient form structure', () {
    test('provides Add and Edit modes', () {
      expect(
        source,
        contains('class IngredientFormScreen'),
      );

      expect(
        source,
        contains('final Ingredient? ingredient'),
      );

      expect(
        source,
        contains("'Edit Ingredient'"),
      );

      expect(
        source,
        contains("'Add Ingredient'"),
      );
    });

    test('requires current authenticated user ID', () {
      expect(
        source,
        contains('final String currentUserId'),
      );

      expect(
        source,
        contains(
          'widget.currentUserId.trim()',
        ),
      );
    });

    test('loads Unit and Supplier references', () {
      expect(
        source,
        contains('UnitOfMeasureRepository'),
      );

      expect(
        source,
        contains('SupplierRepository'),
      );

      expect(
        source,
        contains('_loadReferences()'),
      );

      expect(
        source,
        contains('includeInactive: false'),
      );
    });

    test('filters deleted reference records', () {
      expect(
        source,
        contains('unit.deletedAt == null'),
      );

      expect(
        source,
        contains(
          'supplier.deletedAt == null',
        ),
      );
    });
  });

  group('Ingredient fields', () {
    test('contains core Ingredient fields', () {
      for (final String label in <String>[
        'Ingredient SKU *',
        'Ingredient Name *',
        'Category *',
        'Primary Supplier',
        'Purchase Unit',
        'Usage Unit *',
        'Conversion Factor *',
        'Latest Purchase Cost *',
        'Reorder Level *',
        'Par Level',
        'Notes',
        'Active Ingredient',
      ]) {
        expect(
          source,
          contains(label),
        );
      }
    });

    test('locks SKU during editing', () {
      expect(
        source,
        contains(
          'enabled: !_saving && !_isEditing',
        ),
      );

      expect(
        source,
        contains(
          'SKU is locked to protect references.',
        ),
      );
    });

    test('provides Ingredient categories', () {
      expect(
        source,
        contains(
          'IngredientCategory.values.map',
        ),
      );

      expect(
        source,
        contains(
          'ingredientCategoryLabel(',
        ),
      );
    });
  });

  group('Ingredient validation', () {
    test('validates Ingredient SKU', () {
      expect(
        source,
        contains('_validateSku('),
      );

      expect(
        source,
        contains(
          'Ingredient SKU is required.',
        ),
      );

      expect(
        source,
        contains(
          r"RegExp(r'^[A-Za-z0-9_-]+$')",
        ),
      );
    });

    test('validates Ingredient Name', () {
      expect(
        source,
        contains('_validateName('),
      );

      expect(
        source,
        contains(
          'Ingredient Name is required.',
        ),
      );
    });

    test('validates Units', () {
      expect(
        source,
        contains('_validateUsageUnit('),
      );

      expect(
        source,
        contains('_validatePurchaseUnit('),
      );

      expect(
        source,
        contains(
          'Select an active Usage Unit.',
        ),
      );
    });

    test('validates numeric fields', () {
      expect(
        source,
        contains(
          '_validatePositiveNumber(',
        ),
      );

      expect(
        source,
        contains(
          '_validateNonNegativeNumber(',
        ),
      );

      expect(
        source,
        contains(
          '_validateParLevel(',
        ),
      );
    });

    test('prevents Par Level below Reorder Level', () {
      expect(
        source,
        contains(
          'parLevel < reorderLevel',
        ),
      );

      expect(
        source,
        contains(
          'Par Level cannot be lower than '
          'Reorder Level.',
        ),
      );
    });

    test('validates Notes length', () {
      expect(
        source,
        contains('_validateNotes('),
      );

      expect(
        source,
        contains(
          'Notes cannot exceed 500 characters.',
        ),
      );
    });
  });

  group('Ingredient live cost preview', () {
    test('calculates cost per Usage Unit', () {
      expect(
        source,
        contains(
          'double get _costPerUsageUnit',
        ),
      );

      expect(
        source,
        contains(
          'return purchaseCost / conversionFactor',
        ),
      );
    });

    test('prevents invalid calculation', () {
      expect(
        source,
        contains('conversionFactor <= 0'),
      );

      expect(
        source,
        contains('purchaseCost < 0'),
      );
    });

    test('shows cost preview card', () {
      expect(
        source,
        contains('_buildCostPreview()'),
      );

      expect(
        source,
        contains('Cost per Usage Unit'),
      );

      expect(
        source,
        contains(r'per $usageUnit'),
      );
    });
  });

  group('Ingredient save workflow', () {
    test('uses Ingredient Repository', () {
      expect(
        source,
        contains('IngredientRepository'),
      );

      expect(
        source,
        contains(
          '_ingredientRepository.saveIngredient(',
        ),
      );
    });

    test('constructs and validates Ingredient', () {
      expect(
        source,
        contains(
          'final Ingredient ingredient',
        ),
      );

      expect(
        source,
        contains('ingredient.validate()'),
      );
    });

    test('preserves audit and server version fields', () {
      expect(
        source,
        contains(
          'original?.createdAt ?? now',
        ),
      );

      expect(
        source,
        contains(
          'original?.createdBy ?? userId',
        ),
      );

      expect(
        source,
        contains(
          'original?.serverVersion ?? 0',
        ),
      );
    });

    test('marks saved Ingredient Pending', () {
      expect(
        source,
        contains(
          'MasterSyncStatus.pending',
        ),
      );
    });

    test('triggers automatic Ingredient sync', () {
      expect(
        source,
        contains(
          'MasterDataAutoSync.instance.trigger(',
        ),
      );

      expect(
        source,
        contains(
          'MasterDataAutoSyncReason'
          '.ingredientSaved',
        ),
      );
    });

    test('provides progress and error handling', () {
      expect(
        source,
        contains("'Saving...'"),
      );

      expect(
        source,
        contains('_showSaveError('),
      );

      expect(
        source,
        contains('on StateError catch'),
      );

      expect(
        source,
        contains('on FormatException catch'),
      );
    });
  });

  group('Ingredient unsaved-change protection', () {
    test('tracks dirty state', () {
      expect(
        source,
        contains('bool _dirty = false'),
      );

      expect(
        source,
        contains('_markDirty()'),
      );
    });

    test('uses PopScope', () {
      expect(
        source,
        contains('return PopScope('),
      );

      expect(
        source,
        contains(
          'canPop: !_dirty && !_saving',
        ),
      );
    });

    test('provides discard confirmation', () {
      expect(
        source,
        contains(
          '_confirmDiscardChanges()',
        ),
      );

      expect(
        source,
        contains("'Discard changes?'"),
      );

      expect(
        source,
        contains("'Keep Editing'"),
      );

      expect(
        source,
        contains("'Discard'"),
      );
    });

    test('guards Back and Cancel navigation', () {
      expect(
        source,
        contains('_handleBackNavigation'),
      );

      expect(
        source,
        contains(
          "child: const Text('Cancel')",
        ),
      );
    });
  });

  group('Ingredient stock isolation', () {
    test('does not update Ingredient Inventory', () {
      expect(
        source,
        isNot(
          contains('ingredient_inventory'),
        ),
      );
    });

    test('does not create Ingredient movements', () {
      expect(
        source,
        isNot(
          contains('ingredient_movements'),
        ),
      );
    });
  });
}
