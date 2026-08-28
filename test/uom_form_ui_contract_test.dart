import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Add and Edit Unit form contract', () {
    late String formSource;
    late String listSource;

    setUpAll(() {
      formSource = File(
        'lib/features/master_data/units/presentation/'
        'unit_of_measure_form_screen.dart',
      ).readAsStringSync();

      listSource = File(
        'lib/features/master_data/units/presentation/'
        'unit_of_measure_screen.dart',
      ).readAsStringSync();
    });

    test('supports Add and Edit modes', () {
      expect(
        formSource.contains("'Add Unit'"),
        isTrue,
      );
      expect(
        formSource.contains("'Edit Unit'"),
        isTrue,
      );
      expect(
        formSource.contains('_isEditing'),
        isTrue,
      );
    });

    test('contains the required form controls', () {
      for (final String field in <String>[
        'Unit Code *',
        'Unit Name *',
        'Unit Type *',
        'Base Unit',
        'Conversion Factor',
        'Allow Decimal Quantity',
        'Active Status',
      ]) {
        expect(
          formSource.contains(field),
          isTrue,
          reason: 'Missing form control: $field',
        );
      }
    });

    test('validates code and conversion values', () {
      expect(
        formSource.contains(
          'Unit code is required.',
        ),
        isTrue,
      );
      expect(
        formSource.contains(
          'Use letters, numbers, and underscores only.',
        ),
        isTrue,
      );
      expect(
        formSource.contains(
          'Conversion factor must be greater than zero.',
        ),
        isTrue,
      );
    });

    test('protects the unit code during Edit', () {
      expect(
        formSource.contains(
          'enabled: !_isEditing && !_saving',
        ),
        isTrue,
      );
      expect(
        formSource.contains(
          'Unit code is locked to protect existing references.',
        ),
        isTrue,
      );
    });

    test('protects unsaved changes', () {
      expect(
        formSource.contains('PopScope'),
        isTrue,
      );
      expect(
        formSource.contains('Discard changes?'),
        isTrue,
      );
      expect(
        formSource.contains('Keep Editing'),
        isTrue,
      );
    });

    test('preserves record identity during Edit', () {
      expect(
        formSource.contains(
          'id: original?.id ?? const Uuid().v4()',
        ),
        isTrue,
      );
      expect(
        formSource.contains(
          'createdAt: original?.createdAt ?? now',
        ),
        isTrue,
      );
      expect(
        formSource.contains(
          'syncStatus: MasterSyncStatus.pending',
        ),
        isTrue,
      );
    });

    test('Add Unit opens the form', () {
      expect(
        listSource.contains('_openUnitForm()'),
        isTrue,
      );
      expect(
        listSource.contains('UnitOfMeasureFormScreen'),
        isTrue,
      );
    });

    test('phone and tablet layouts support Edit', () {
      expect(
        listSource.contains("value: 'edit'"),
        isTrue,
      );
      expect(
        listSource.contains("tooltip: 'Edit'"),
        isTrue,
      );
      expect(
        listSource.contains('required this.onEdit'),
        isTrue,
      );
    });

    test('successful form save refreshes the list', () {
      expect(
        listSource.contains('saved != true'),
        isTrue,
      );
      expect(
        listSource.contains('await _loadUnits()'),
        isTrue,
      );
      expect(
        listSource.contains(
          'Unit created successfully.',
        ),
        isTrue,
      );
      expect(
        listSource.contains(
          'Unit updated successfully.',
        ),
        isTrue,
      );
    });
  });
}
