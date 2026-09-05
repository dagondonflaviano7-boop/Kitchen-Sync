import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String product;
  late String repository;
  late String dao;

  setUpAll(() {
    product = File(
      'lib/domain/models/product.dart',
    ).readAsStringSync();

    repository = File(
      'lib/data/repositories/'
      'product_repository.dart',
    ).readAsStringSync();

    dao = File(
      'lib/data/local/daos/product_dao.dart',
    ).readAsStringSync();
  });

  group('Product sync model metadata', () {
    test('imports shared sync status', () {
      expect(
        product,
        contains(
          "models/unit_of_measure.dart",
        ),
      );
    });

    test('contains sync metadata fields', () {
      expect(
        product,
        contains(
          'final MasterSyncStatus syncStatus;',
        ),
      );

      expect(
        product,
        contains(
          'final int serverVersion;',
        ),
      );

      expect(
        product,
        contains(
          'final DateTime? deletedAt;',
        ),
      );
    });

    test('uses safe sync defaults', () {
      expect(
        product,
        contains(
          'this.syncStatus = '
          'MasterSyncStatus.pending',
        ),
      );

      expect(
        product,
        contains(
          'this.serverVersion = 0',
        ),
      );
    });

    test('provides Product deletion state', () {
      expect(
        product,
        contains(
          'bool get isDeleted',
        ),
      );

      expect(
        product,
        contains(
          'return deletedAt != null',
        ),
      );
    });

    test('rejects negative server version', () {
      expect(
        product,
        contains(
          'if (serverVersion < 0)',
        ),
      );

      expect(
        product,
        contains(
          'Server Version must be '
          'zero or greater.',
        ),
      );
    });

    test('requires tombstones to be inactive', () {
      expect(
        product,
        contains(
          'deletedAt != null && active',
        ),
      );

      expect(
        product,
        contains(
          'A deleted Product cannot '
          'remain active.',
        ),
      );
    });

    test('maps sync metadata to SQLite', () {
      expect(
        product,
        contains("'sync_status'"),
      );

      expect(
        product,
        contains("'server_version'"),
      );

      expect(
        product,
        contains("'deleted_at'"),
      );
    });

    test('maps sync metadata from SQLite', () {
      expect(
        product,
        contains(
          "map['sync_status']",
        ),
      );

      expect(
        product,
        contains(
          "map['server_version']",
        ),
      );

      expect(
        product,
        contains(
          "map['deleted_at']",
        ),
      );
    });

    test('maps sync metadata to Firebase', () {
      expect(
        product,
        contains("'syncStatus'"),
      );

      expect(
        product,
        contains("'serverVersion'"),
      );

      expect(
        product,
        contains("'deletedAt'"),
      );
    });

    test('supports sync metadata in copyWith', () {
      expect(
        product,
        contains(
          'MasterSyncStatus? syncStatus',
        ),
      );

      expect(
        product,
        contains(
          'int? serverVersion',
        ),
      );

      expect(
        product,
        contains(
          'bool clearDeletedAt = false',
        ),
      );
    });
  });

  group('Product repository sync lifecycle', () {
    test('rejects deleted Product edits', () {
      expect(
        repository,
        contains(
          'existing?.isDeleted ?? false',
        ),
      );

      expect(
        repository,
        contains(
          'A deleted Product cannot '
          'be edited.',
        ),
      );
    });

    test('marks Product saves pending', () {
      expect(
        repository,
        contains(
          'syncStatus: '
          'MasterSyncStatus.pending',
        ),
      );
    });

    test('preserves server version', () {
      expect(
        repository,
        contains(
          'existing?.serverVersion',
        ),
      );
    });

    test('clears stale tombstones', () {
      expect(
        repository,
        contains(
          'clearDeletedAt: true',
        ),
      );
    });

    test('marks status changes pending', () {
      expect(
        dao,
        contains(
          "'sync_status': 'PENDING'",
        ),
      );
    });
  });
}
