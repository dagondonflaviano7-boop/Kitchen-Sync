import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/local/daos/product_dao.dart',
    ).readAsStringSync();
  });

  group('Product DAO sync lifecycle', () {
    test('finds Pending and Error Products', () {
      expect(
        source,
        contains(
          'Future<List<Product>> findPending(',
        ),
      );

      expect(
        source,
        contains(
          "'sync_status IN (?, ?)'",
        ),
      );

      expect(source, contains("'PENDING'"));
      expect(source, contains("'ERROR'"));
    });

    test('validates pending limit', () {
      expect(
        source,
        contains('if (limit < 1)'),
      );

      expect(
        source,
        contains(
          'Pending synchronization limit ',
        ),
      );

      expect(
        source,
        contains(
          'must be greater than zero.',
        ),
      );
    });

    test('orders the synchronization queue', () {
      expect(
        source,
        contains(
          "orderBy: 'updated_at, id'",
        ),
      );
    });

    test('marks Product Syncing', () {
      expect(
        source,
        contains(
          'Future<void> markSyncing(',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.syncing',
        ),
      );
    });

    test('marks Product Synced', () {
      expect(
        source,
        contains(
          'Future<void> markSynced(',
        ),
      );

      expect(
        source,
        contains(
          "'sync_status': 'SYNCED'",
        ),
      );

      expect(
        source,
        contains(
          "'server_version': serverVersion",
        ),
      );
    });

    test('rejects negative server versions', () {
      expect(
        source,
        contains(
          'if (serverVersion < 0)',
        ),
      );

      expect(
        source,
        contains(
          'Server version must be '
          'zero or greater.',
        ),
      );
    });

    test('marks Product Sync Error', () {
      expect(
        source,
        contains(
          'Future<void> markSyncError(',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.error',
        ),
      );
    });

    test('supports Product tombstones', () {
      expect(
        source,
        contains(
          'Future<void> softDelete(',
        ),
      );

      expect(
        source,
        contains("'active': 0"),
      );

      expect(
        source,
        contains(
          "'sync_status': 'PENDING'",
        ),
      );

      expect(
        source,
        contains(
          "'deleted_at': timestamp",
        ),
      );
    });

    test('prevents duplicate deletion', () {
      expect(
        source,
        contains(
          'AND deleted_at IS NULL',
        ),
      );

      expect(
        source,
        contains(
          'or was already deleted.',
        ),
      );
    });

    test('supports remote Product upsert', () {
      expect(
        source,
        contains(
          'Future<void> upsertRemote(',
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
          'ConflictAlgorithm.replace',
        ),
      );
    });

    test('validates remote Product', () {
      expect(
        source,
        contains(
          'product.validate()',
        ),
      );

      expect(
        source,
        contains(
          'synchronized.validate()',
        ),
      );
    });

    test('throws when Product is missing', () {
      expect(
        source,
        contains(
          'The Product record was not found.',
        ),
      );
    });
  });
}
