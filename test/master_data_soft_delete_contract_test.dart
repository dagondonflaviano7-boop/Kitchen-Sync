import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Master Data soft-delete contracts', () {
    late String unitDaoSource;
    late String unitRepositorySource;
    late String unitScreenSource;

    late String supplierDaoSource;
    late String supplierRepositorySource;
    late String supplierScreenSource;

    setUpAll(() {
      unitDaoSource = File(
        'lib/data/local/daos/'
        'unit_of_measure_dao.dart',
      ).readAsStringSync();

      unitRepositorySource = File(
        'lib/data/repositories/'
        'unit_of_measure_repository.dart',
      ).readAsStringSync();

      unitScreenSource = File(
        'lib/features/master_data/units/presentation/'
        'unit_of_measure_screen.dart',
      ).readAsStringSync();

      supplierDaoSource = File(
        'lib/data/local/daos/'
        'supplier_dao.dart',
      ).readAsStringSync();

      supplierRepositorySource = File(
        'lib/data/repositories/'
        'supplier_repository.dart',
      ).readAsStringSync();

      supplierScreenSource = File(
        'lib/features/master_data/suppliers/'
        'presentation/supplier_screen.dart',
      ).readAsStringSync();
    });

    group('Unit of Measure soft delete', () {
      test('DAO provides a softDelete method', () {
        expect(
          unitDaoSource.contains(
            'Future<void> softDelete(',
          ),
          isTrue,
        );
      });

      test('does not physically delete the unit row', () {
        expect(
          unitDaoSource.contains(
            "database.delete(\n      'units_of_measure'",
          ),
          isFalse,
        );

        expect(
          unitDaoSource.contains(
            "DELETE FROM units_of_measure",
          ),
          isFalse,
        );
      });

      test('marks the unit inactive', () {
        expect(
          unitDaoSource.contains(
            "'active': 0",
          ),
          isTrue,
        );
      });

      test('records a deletion timestamp', () {
        expect(
          unitDaoSource.contains(
            "'deleted_at': timestamp",
          ),
          isTrue,
        );
      });

      test('updates the modification timestamp', () {
        expect(
          unitDaoSource.contains(
            "'updated_at': timestamp",
          ),
          isTrue,
        );
      });

      test('marks the deleted unit pending sync', () {
        expect(
          unitDaoSource.contains(
            "'sync_status': 'PENDING'",
          ),
          isTrue,
        );
      });

      test('prevents deleting an already deleted unit', () {
        expect(
          unitDaoSource.contains(
            "where: 'id = ? AND deleted_at IS NULL'",
          ),
          isTrue,
        );
      });

      test('reports missing or already deleted records', () {
        expect(
          unitDaoSource.contains(
            'was not found or was already deleted',
          ),
          isTrue,
        );
      });

      test('normal list excludes deleted units', () {
        expect(
          unitDaoSource.contains(
            'deleted_at IS NULL',
          ),
          isTrue,
        );
      });

      test('DAO checks whether a unit is referenced', () {
        expect(
          unitDaoSource.contains(
            'Future<bool> isReferenced(',
          ),
          isTrue,
        );
      });

      test('checks unit conversion references', () {
        expect(
          unitDaoSource.contains(
            "'unit_conversions'",
          ),
          isTrue,
        );

        expect(
          unitDaoSource.contains(
            'source_unit_code = ?',
          ),
          isTrue,
        );

        expect(
          unitDaoSource.contains(
            'target_unit_code = ?',
          ),
          isTrue,
        );
      });

      test('checks packaging conversion references', () {
        expect(
          unitDaoSource.contains(
            "'product_packaging_conversions'",
          ),
          isTrue,
        );
      });

      test('repository exposes deleteUnit', () {
        expect(
          unitRepositorySource.contains(
            'Future<void> deleteUnit(',
          ),
          isTrue,
        );
      });

      test('repository protects standard units', () {
        for (final String code in <String>[
          'PCS',
          'GRAM',
          'KG',
          'ML',
          'LITER',
          'PACK',
          'BOX',
          'BOTTLE',
          'CAN',
        ]) {
          expect(
            unitRepositorySource.contains(
              "'$code'",
            ),
            isTrue,
            reason: 'Missing protected standard code: $code',
          );
        }
      });

      test('repository gives protected-unit guidance', () {
        expect(
          unitRepositorySource.contains(
            'Standard units cannot be deleted',
          ),
          isTrue,
        );

        expect(
          unitRepositorySource.contains(
            'Deactivate the unit instead',
          ),
          isTrue,
        );
      });

      test('repository blocks referenced units', () {
        expect(
          unitRepositorySource.contains(
            'unitDao.isReferenced',
          ),
          isTrue,
        );

        expect(
          unitRepositorySource.contains(
            'used by existing records',
          ),
          isTrue,
        );
      });

      test('repository performs the deletion transactionally', () {
        expect(
          unitRepositorySource.contains(
            'database.transaction',
          ),
          isTrue,
        );

        expect(
          unitRepositorySource.contains(
            'unitDao.softDelete',
          ),
          isTrue,
        );
      });

      test('Unit screen requires delete confirmation', () {
        expect(
          unitScreenSource.contains(
            "'Delete unit?'",
          ),
          isTrue,
        );

        expect(
          unitScreenSource.contains(
            '_confirmDeleteUnit',
          ),
          isTrue,
        );
      });

      test('Unit screen exposes Delete actions', () {
        expect(
          unitScreenSource.contains(
            "value: 'delete'",
          ),
          isTrue,
        );

        expect(
          unitScreenSource.contains(
            "tooltip: 'Delete'",
          ),
          isTrue,
        );
      });

      test('Unit screen reloads after deletion', () {
        final int deleteCall = unitScreenSource.indexOf(
          '_repository.deleteUnit',
        );

        final int reloadCall = unitScreenSource.indexOf(
          'await _loadUnits()',
          deleteCall,
        );

        expect(
          deleteCall,
          greaterThanOrEqualTo(0),
        );

        expect(
          reloadCall,
          greaterThan(deleteCall),
        );
      });

      test('Unit screen handles repository errors', () {
        expect(
          unitScreenSource.contains(
            'on StateError catch',
          ),
          isTrue,
        );

        expect(
          unitScreenSource.contains(
            '_showDeleteError',
          ),
          isTrue,
        );
      });
    });

    group('Supplier soft delete', () {
      test('DAO provides a softDelete method', () {
        expect(
          supplierDaoSource.contains(
            'Future<void> softDelete(',
          ),
          isTrue,
        );
      });

      test('does not physically delete the supplier row', () {
        expect(
          supplierDaoSource.contains(
            "database.delete(\n      'suppliers'",
          ),
          isFalse,
        );

        expect(
          supplierDaoSource.contains(
            'DELETE FROM suppliers',
          ),
          isFalse,
        );
      });

      test('marks the supplier inactive', () {
        expect(
          supplierDaoSource.contains(
            "'active': 0",
          ),
          isTrue,
        );
      });

      test('records the deletion timestamp', () {
        expect(
          supplierDaoSource.contains(
            "'deleted_at': timestamp",
          ),
          isTrue,
        );
      });

      test('updates the supplier timestamp', () {
        expect(
          supplierDaoSource.contains(
            "'updated_at': timestamp",
          ),
          isTrue,
        );
      });

      test('records the authenticated updater', () {
        expect(
          supplierDaoSource.contains(
            "'updated_by': updatedBy",
          ),
          isTrue,
        );
      });

      test('marks the supplier pending sync', () {
        expect(
          supplierDaoSource.contains(
            "'sync_status': 'PENDING'",
          ),
          isTrue,
        );
      });

      test('prevents deleting an already deleted supplier', () {
        expect(
          supplierDaoSource.contains(
            "where: 'id = ? AND deleted_at IS NULL'",
          ),
          isTrue,
        );
      });

      test('normal supplier queries exclude tombstones', () {
        expect(
          supplierDaoSource.contains(
            'deleted_at IS NULL',
          ),
          isTrue,
        );
      });

      test('DAO checks supplier references', () {
        expect(
          supplierDaoSource.contains(
            'Future<bool> isReferenced(',
          ),
          isTrue,
        );
      });

      test('repository exposes deleteSupplier', () {
        expect(
          supplierRepositorySource.contains(
            'Future<void> deleteSupplier(',
          ),
          isTrue,
        );
      });

      test('repository requires authenticated identity', () {
        expect(
          supplierRepositorySource.contains(
            'currentUserId',
          ),
          isTrue,
        );

        expect(
          supplierRepositorySource.contains(
            'Authenticated user identity is required',
          ),
          isTrue,
        );
      });

      test('repository blocks referenced suppliers', () {
        expect(
          supplierRepositorySource.contains(
            'supplierDao.isReferenced',
          ),
          isTrue,
        );

        expect(
          supplierRepositorySource.contains(
            'used by existing records',
          ),
          isTrue,
        );

        expect(
          supplierRepositorySource.contains(
            'Deactivate it instead',
          ),
          isTrue,
        );
      });

      test('repository performs deletion transactionally', () {
        expect(
          supplierRepositorySource.contains(
            'database.transaction',
          ),
          isTrue,
        );

        expect(
          supplierRepositorySource.contains(
            'supplierDao.softDelete',
          ),
          isTrue,
        );
      });

      test('repository passes authenticated ID to DAO', () {
        expect(
          supplierRepositorySource.contains(
            'updatedBy: currentUserId',
          ),
          isTrue,
        );
      });

      test('Supplier screen requires confirmation', () {
        expect(
          supplierScreenSource.contains(
            "'Delete supplier?'",
          ),
          isTrue,
        );

        expect(
          supplierScreenSource.contains(
            '_confirmDeleteSupplier',
          ),
          isTrue,
        );
      });

      test('Supplier screen exposes Delete actions', () {
        expect(
          supplierScreenSource.contains(
            "value: 'delete'",
          ),
          isTrue,
        );

        expect(
          supplierScreenSource.contains(
            "tooltip: 'Delete'",
          ),
          isTrue,
        );
      });

      test('Supplier screen supplies audit ID', () {
        expect(
          supplierScreenSource.contains(
            'currentUserId: currentUserId',
          ),
          isTrue,
        );
      });

      test('Supplier screen reloads after deletion', () {
        final int deleteCall = supplierScreenSource.indexOf(
          '_repository.deleteSupplier',
        );

        final int reloadCall = supplierScreenSource.indexOf(
          'await _loadSuppliers()',
          deleteCall,
        );

        expect(
          deleteCall,
          greaterThanOrEqualTo(0),
        );

        expect(
          reloadCall,
          greaterThan(deleteCall),
        );
      });

      test('Supplier screen handles repository errors', () {
        expect(
          supplierScreenSource.contains(
            'on StateError catch',
          ),
          isTrue,
        );

        expect(
          supplierScreenSource.contains(
            '_showDeleteError',
          ),
          isTrue,
        );
      });
    });
  });
}
