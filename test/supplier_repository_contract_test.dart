import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supplier persistence contracts', () {
    late String daoSource;
    late String repositorySource;

    setUpAll(() {
      daoSource = File(
        'lib/data/local/daos/supplier_dao.dart',
      ).readAsStringSync();

      repositorySource = File(
        'lib/data/repositories/'
        'supplier_repository.dart',
      ).readAsStringSync();
    });

    test('DAO targets the existing suppliers table', () {
      expect(
        daoSource.contains("'suppliers'"),
        isTrue,
      );

      expect(
        daoSource.contains(
          'ConflictAlgorithm.replace',
        ),
        isTrue,
      );
    });

    test('DAO supports supplier lookup', () {
      expect(
        daoSource.contains('findById'),
        isTrue,
      );

      expect(
        daoSource.contains('findByCode'),
        isTrue,
      );
    });

    test('DAO supports supplier search', () {
      expect(
        daoSource.contains('supplier_code LIKE ?'),
        isTrue,
      );

      expect(
        daoSource.contains('supplier_name LIKE ?'),
        isTrue,
      );

      expect(
        daoSource.contains('contact_person LIKE ?'),
        isTrue,
      );
    });

    test('DAO excludes soft-deleted suppliers', () {
      expect(
        daoSource.contains('deleted_at IS NULL'),
        isTrue,
      );
    });

    test('repository validates before saving', () {
      expect(
        repositorySource.contains(
          'supplier.validate()',
        ),
        isTrue,
      );
    });

    test('repository prevents duplicate codes', () {
      expect(
        repositorySource.contains(
          'supplierDao.codeExists',
        ),
        isTrue,
      );

      expect(
        repositorySource.contains(
          'already exists',
        ),
        isTrue,
      );
    });

    test('repository supports activation changes', () {
      expect(
        repositorySource.contains(
          'setSupplierActive',
        ),
        isTrue,
      );

      expect(
        repositorySource.contains(
          'supplierDao.setActive',
        ),
        isTrue,
      );
    });

    test('activation marks the supplier pending', () {
      expect(
        daoSource.contains(
          "'sync_status': 'PENDING'",
        ),
        isTrue,
      );
    });
  });
}
