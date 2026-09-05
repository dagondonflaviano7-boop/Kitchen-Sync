import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String service;
  late String hub;

  setUpAll(() {
    service = File(
      'lib/data/services/'
      'master_data_sync_service.dart',
    ).readAsStringSync();

    hub = File(
      'lib/features/master_data/'
      'presentation/master_data_hub.dart',
    ).readAsStringSync();
  });

  group('Product Master synchronization', () {
    test('imports Product DAO and model', () {
      expect(
        service,
        contains(
          'daos/product_dao.dart',
        ),
      );

      expect(
        service,
        contains(
          'models/product.dart',
        ),
      );
    });

    test('adds Product counters', () {
      expect(
        service,
        contains(
          'final int uploadedProducts;',
        ),
      );

      expect(
        service,
        contains(
          'final int downloadedProducts;',
        ),
      );
    });

    test('adds offline Product defaults', () {
      expect(
        service,
        contains(
          'uploadedProducts = 0',
        ),
      );

      expect(
        service,
        contains(
          'downloadedProducts = 0',
        ),
      );
    });

    test('provides Product DAO dependency', () {
      expect(
        service,
        contains(
          'final ProductDao productDao;',
        ),
      );

      expect(
        service,
        contains(
          'this.productDao = '
          'const ProductDao()',
        ),
      );
    });

    test('uploads pending Products', () {
      expect(
        service,
        contains(
          'productDao.findPending(database)',
        ),
      );

      expect(
        service,
        contains(
          'remoteRepository.uploadProduct(',
        ),
      );
    });

    test('uses Product upload lifecycle', () {
      expect(
        service,
        contains(
          'productDao.markSyncing(',
        ),
      );

      expect(
        service,
        contains(
          'productDao.markSynced(',
        ),
      );

      expect(
        service,
        contains(
          'productDao.markSyncError(',
        ),
      );
    });

    test('downloads remote Products', () {
      expect(
        service,
        contains(
          'remoteRepository.downloadProducts()',
        ),
      );

      expect(
        service,
        contains(
          'productDao.upsertRemote(',
        ),
      );
    });

    test('preserves unresolved local Products', () {
      expect(
        service,
        contains(
          '_hasUnresolvedLocalProduct(',
        ),
      );

      expect(
        service,
        contains(
          'preservedLocalChanges += 1',
        ),
      );
    });

    test('compares Product server versions', () {
      expect(
        service,
        contains(
          '_shouldApplyRemoteProduct(',
        ),
      );

      expect(
        service,
        contains(
          'remote.serverVersion > '
          'local.serverVersion',
        ),
      );

      expect(
        service,
        contains(
          'remote.serverVersion < '
          'local.serverVersion',
        ),
      );
    });

    test('uses Product timestamp fallback', () {
      expect(
        service,
        contains(
          'remote.updatedAt.isAfter(',
        ),
      );
    });

    test('returns Product counters', () {
      expect(
        service,
        contains(
          'uploadedProducts: '
          'uploadedProducts',
        ),
      );

      expect(
        service,
        contains(
          'downloadedProducts: '
          'downloadedProducts',
        ),
      );
    });

    test('includes Products in Hub totals', () {
      expect(
        hub,
        contains(
          'result.uploadedProducts',
        ),
      );

      expect(
        hub,
        contains(
          'result.downloadedProducts',
        ),
      );
    });

    test('includes Products in Hub wording', () {
      expect(
        hub,
        contains(
          'and Products with Firebase.',
        ),
      );
    });
  });
}
