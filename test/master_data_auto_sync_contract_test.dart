import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Automatic Master Data synchronization', () {
    late String coordinatorSource;
    late String shellSource;
    late String unitFormSource;
    late String unitScreenSource;
    late String supplierFormSource;
    late String supplierScreenSource;

    setUpAll(() {
      coordinatorSource = File(
        'lib/data/services/master_data_auto_sync.dart',
      ).readAsStringSync();

      shellSource = File(
        'lib/features/dashboard/presentation/'
        'adaptive_shell.dart',
      ).readAsStringSync();

      unitFormSource = File(
        'lib/features/master_data/units/presentation/'
        'unit_of_measure_form_screen.dart',
      ).readAsStringSync();

      unitScreenSource = File(
        'lib/features/master_data/units/presentation/'
        'unit_of_measure_screen.dart',
      ).readAsStringSync();

      supplierFormSource = File(
        'lib/features/master_data/suppliers/presentation/'
        'supplier_form_screen.dart',
      ).readAsStringSync();

      supplierScreenSource = File(
        'lib/features/master_data/suppliers/presentation/'
        'supplier_screen.dart',
      ).readAsStringSync();
    });

    test('coordinator owns one sync service', () {
      expect(
        coordinatorSource.contains(
          'final MasterDataSyncService _syncService',
        ),
        isTrue,
      );
    });

    test('coordinator prevents overlapping sync', () {
      expect(
        coordinatorSource.contains('_activeSync'),
        isTrue,
      );

      expect(
        coordinatorSource.contains(
          '_syncService.isRunning',
        ),
        isTrue,
      );
    });

    test('automatic sync handles failures safely', () {
      expect(
        coordinatorSource.contains(
          'catch (error, stackTrace)',
        ),
        isTrue,
      );

      expect(
        coordinatorSource.contains('return null'),
        isTrue,
      );
    });

    test('login triggers automatic sync', () {
      expect(
        shellSource.contains(
          'MasterDataAutoSyncReason.login',
        ),
        isTrue,
      );
    });

    test('app resume triggers automatic sync', () {
      expect(
        shellSource.contains(
          'MasterDataAutoSyncReason.appResume',
        ),
        isTrue,
      );
    });

    test('network recovery triggers automatic sync', () {
      expect(
        shellSource.contains(
          'connectivityRestored',
        ),
        isTrue,
      );
    });

    test('Unit Save triggers sync', () {
      expect(
        unitFormSource.contains(
          'MasterDataAutoSyncReason.unitSaved',
        ),
        isTrue,
      );
    });

    test('Unit status and deletion trigger sync', () {
      expect(
        unitScreenSource.contains(
          'unitStatusChanged',
        ),
        isTrue,
      );

      expect(
        unitScreenSource.contains(
          'unitDeleted',
        ),
        isTrue,
      );
    });

    test('Supplier Save triggers sync', () {
      expect(
        supplierFormSource.contains(
          'MasterDataAutoSyncReason.supplierSaved',
        ),
        isTrue,
      );
    });

    test('Supplier status and deletion trigger sync', () {
      expect(
        supplierScreenSource.contains(
          'supplierStatusChanged',
        ),
        isTrue,
      );

      expect(
        supplierScreenSource.contains(
          'supplierDeleted',
        ),
        isTrue,
      );
    });

    test('manual Sync action remains available', () {
      final String hubSource = File(
        'lib/features/master_data/presentation/'
        'master_data_hub.dart',
      ).readAsStringSync();

      expect(
        hubSource.contains("'Sync Master Data'"),
        isTrue,
      );
    });
  });
}
