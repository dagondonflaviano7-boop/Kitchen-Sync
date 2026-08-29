import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Master Data DAO sync lifecycle', () {
    late String unitDao;
    late String supplierDao;

    setUpAll(() {
      unitDao = File(
        'lib/data/local/daos/'
        'unit_of_measure_dao.dart',
      ).readAsStringSync();

      supplierDao = File(
        'lib/data/local/daos/'
        'supplier_dao.dart',
      ).readAsStringSync();
    });

    void verifyLifecycle(String source) {
      expect(
        source.contains('findPending'),
        isTrue,
      );

      expect(
        source.contains(
          "sync_status IN (?, ?)",
        ),
        isTrue,
      );

      expect(
        source.contains("'PENDING'"),
        isTrue,
      );

      expect(
        source.contains("'ERROR'"),
        isTrue,
      );

      expect(
        source.contains('findAllIncludingDeleted'),
        isTrue,
      );

      expect(
        source.contains('markSyncing'),
        isTrue,
      );

      expect(
        source.contains(
          "'sync_status': 'SYNCING'",
        ),
        isTrue,
      );

      expect(
        source.contains('markSynced'),
        isTrue,
      );

      expect(
        source.contains(
          "'sync_status': 'SYNCED'",
        ),
        isTrue,
      );

      expect(
        source.contains(
          "'server_version': serverVersion",
        ),
        isTrue,
      );

      expect(
        source.contains('markSyncError'),
        isTrue,
      );

      expect(
        source.contains(
          "'sync_status': 'ERROR'",
        ),
        isTrue,
      );

      expect(
        source.contains('upsertRemote'),
        isTrue,
      );

      expect(
        source.contains(
          'ConflictAlgorithm.replace',
        ),
        isTrue,
      );
    }

    test('Unit DAO supports full sync lifecycle', () {
      verifyLifecycle(unitDao);
    });

    test(
      'Supplier DAO supports full sync lifecycle',
      () {
        verifyLifecycle(supplierDao);
      },
    );

    test('pending queries include tombstones', () {
      final int unitStart = unitDao.indexOf('findPending');

      final int unitEnd = unitDao.indexOf(
        'findAllIncludingDeleted',
        unitStart,
      );

      final String unitPending = unitDao.substring(unitStart, unitEnd);

      final int supplierStart = supplierDao.indexOf('findPending');

      final int supplierEnd = supplierDao.indexOf(
        'findAllIncludingDeleted',
        supplierStart,
      );

      final String supplierPending = supplierDao.substring(
        supplierStart,
        supplierEnd,
      );

      expect(
        unitPending.contains(
          'deleted_at IS NULL',
        ),
        isFalse,
      );

      expect(
        supplierPending.contains(
          'deleted_at IS NULL',
        ),
        isFalse,
      );
    });

    test('remote upserts become locally synced', () {
      expect(
        unitDao.contains(
          "values['sync_status'] = 'SYNCED'",
        ),
        isTrue,
      );

      expect(
        supplierDao.contains(
          "values['sync_status'] = 'SYNCED'",
        ),
        isTrue,
      );
    });
  });
}
