import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Master Data sync service contract', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/data/services/'
        'master_data_sync_service.dart',
      ).readAsStringSync();
    });

    test('checks connectivity before syncing', () {
      expect(
        source.contains(
          'connectivityService.isOnline',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'MasterDataSyncResult.offline',
        ),
        isTrue,
      );
    });

    test('prevents simultaneous sync runs', () {
      expect(
        source.contains('bool _running = false'),
        isTrue,
      );

      expect(
        source.contains(
          'synchronization is already running',
        ),
        isTrue,
      );

      expect(
        source.contains('_running = false'),
        isTrue,
      );
    });

    test('uploads pending Units', () {
      expect(
        source.contains('unitDao.findPending'),
        isTrue,
      );

      expect(
        source.contains('unitDao.markSyncing'),
        isTrue,
      );

      expect(
        source.contains(
          'remoteRepository.uploadUnit',
        ),
        isTrue,
      );

      expect(
        source.contains('unitDao.markSynced'),
        isTrue,
      );
    });

    test('uploads pending Suppliers', () {
      expect(
        source.contains(
          'supplierDao.findPending',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'supplierDao.markSyncing',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'remoteRepository.uploadSupplier',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'supplierDao.markSynced',
        ),
        isTrue,
      );
    });

    test('marks failed uploads as errors', () {
      expect(
        source.contains(
          'unitDao.markSyncError',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'supplierDao.markSyncError',
        ),
        isTrue,
      );
    });

    test('downloads remote master data', () {
      expect(
        source.contains(
          'remoteRepository.downloadUnits',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'remoteRepository.downloadSuppliers',
        ),
        isTrue,
      );
    });

    test('uses tombstone-aware lookups', () {
      expect(
        source.contains(
          'findByIdIncludingDeleted',
        ),
        isTrue,
      );
    });

    test('preserves unresolved local changes', () {
      expect(
        source.contains(
          'MasterSyncStatus.pending',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'MasterSyncStatus.syncing',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'MasterSyncStatus.error',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'preservedLocalChanges',
        ),
        isTrue,
      );
    });

    test('compares server versions', () {
      expect(
        source.contains(
          'remote.serverVersion >',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'remote.serverVersion <',
        ),
        isTrue,
      );
    });

    test('uses timestamps as equal-version fallback', () {
      expect(
        source.contains(
          'remote.updatedAt.isAfter',
        ),
        isTrue,
      );
    });

    test('applies remote records as synced', () {
      expect(
        source.contains(
          'unitDao.upsertRemote',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'supplierDao.upsertRemote',
        ),
        isTrue,
      );
    });
  });
}
