import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supplier interface contract', () {
    late String listSource;
    late String formSource;
    late String hubSource;

    setUpAll(() {
      listSource = File(
        'lib/features/master_data/suppliers/presentation/'
        'supplier_screen.dart',
      ).readAsStringSync();

      formSource = File(
        'lib/features/master_data/suppliers/presentation/'
        'supplier_form_screen.dart',
      ).readAsStringSync();

      hubSource = File(
        'lib/features/master_data/presentation/'
        'master_data_hub.dart',
      ).readAsStringSync();
    });

    test('Master Data Hub opens Suppliers', () {
      expect(
        hubSource.contains('supplier_screen.dart'),
        isTrue,
      );

      expect(
        hubSource.contains('SupplierScreen'),
        isTrue,
      );

      expect(
        hubSource.contains("title: 'Suppliers'"),
        isTrue,
      );
    });

    test('Supplier List loads repository data', () {
      expect(
        listSource.contains(
          '_repository.searchSuppliers',
        ),
        isTrue,
      );

      expect(
        listSource.contains('_loadSuppliers'),
        isTrue,
      );
    });

    test('Supplier List supports status filters', () {
      for (final String status in <String>[
        'SupplierStatusFilter.all',
        'SupplierStatusFilter.active',
        'SupplierStatusFilter.inactive',
      ]) {
        expect(
          listSource.contains(status),
          isTrue,
          reason: 'Missing status filter: $status',
        );
      }
    });

    test('Supplier List supports Add and Edit', () {
      expect(
        listSource.contains("'Add Supplier'"),
        isTrue,
      );

      expect(
        listSource.contains('SupplierFormScreen'),
        isTrue,
      );

      expect(
        listSource.contains("value: 'edit'"),
        isTrue,
      );

      expect(
        listSource.contains("tooltip: 'Edit'"),
        isTrue,
      );
    });

    test('Supplier List supports activation', () {
      expect(
        listSource.contains(
          '_repository.setSupplierActive',
        ),
        isTrue,
      );

      expect(
        listSource.contains(
          "'Activate supplier?'",
        ),
        isTrue,
      );

      expect(
        listSource.contains(
          "'Deactivate supplier?'",
        ),
        isTrue,
      );
    });

    test('Supplier List has phone and tablet layouts', () {
      expect(
        listSource.contains('_SupplierCard'),
        isTrue,
      );

      expect(
        listSource.contains('_SupplierTable'),
        isTrue,
      );

      expect(
        listSource.contains(
          'constraints.maxWidth >= 760',
        ),
        isTrue,
      );
    });

    test('Supplier form contains required fields', () {
      for (final String field in <String>[
        'Supplier Code *',
        'Supplier Name *',
        'Contact Person',
        'Phone',
        'Email',
        'Address',
        'Tax ID or TIN',
        'Payment Terms',
        'Lead Time in Days *',
        'Active Status',
      ]) {
        expect(
          formSource.contains(field),
          isTrue,
          reason: 'Missing Supplier field: $field',
        );
      }
    });

    test('Supplier form protects record identity', () {
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

    test('Supplier form protects unsaved changes', () {
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

    test('Supplier form saves through repository', () {
      expect(
        formSource.contains(
          '_repository.saveSupplier',
        ),
        isTrue,
      );

      expect(
        formSource.contains(
          'supplier.validate()',
        ),
        isTrue,
      );
    });
  });

  authenticatedSupplierAuditTests();
}

void authenticatedSupplierAuditTests() {
  final String shellSource = File(
    'lib/features/dashboard/presentation/'
    'adaptive_shell.dart',
  ).readAsStringSync();

  final String hubSource = File(
    'lib/features/master_data/presentation/'
    'master_data_hub.dart',
  ).readAsStringSync();

  final String supplierScreenSource = File(
    'lib/features/master_data/suppliers/presentation/'
    'supplier_screen.dart',
  ).readAsStringSync();

  final String supplierFormSource = File(
    'lib/features/master_data/suppliers/presentation/'
    'supplier_form_screen.dart',
  ).readAsStringSync();

  group('Authenticated Supplier audit identity', () {
    test('Master Data Hub requires a user ID', () {
      expect(
        hubSource.contains(
          'required this.currentUserId',
        ),
        isTrue,
      );
    });

    test('Adaptive Shell supplies profile ID', () {
      expect(
        shellSource.contains(
          'widget.sessionContext.profile.id',
        ),
        isTrue,
      );
    });

    test('Supplier screen receives the user ID', () {
      expect(
        hubSource.contains(
          'currentUserId: currentUserId',
        ),
        isTrue,
      );
    });

    test('Supplier screen forwards the user ID', () {
      expect(
        supplierScreenSource.contains(
          'currentUserId: widget.currentUserId',
        ),
        isTrue,
      );
    });

    test('Supplier form records the audit identity', () {
      expect(
        supplierFormSource.contains(
          'original?.createdBy ?? widget.currentUserId',
        ),
        isTrue,
      );

      expect(
        supplierFormSource.contains(
          'updatedBy: widget.currentUserId',
        ),
        isTrue,
      );
    });

    test('fixed ADMIN audit identity is removed', () {
      expect(
        hubSource.contains(
          "currentUserId: 'ADMIN'",
        ),
        isFalse,
      );
    });
  });
}
