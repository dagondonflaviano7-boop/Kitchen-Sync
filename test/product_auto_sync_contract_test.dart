import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String coordinator;
  late String form;
  late String screen;

  setUpAll(() {
    coordinator = File(
      'lib/data/services/master_data_auto_sync.dart',
    ).readAsStringSync();

    form = File(
      'lib/features/master_data/products/'
      'presentation/product_form_screen.dart',
    ).readAsStringSync();

    screen = File(
      'lib/features/master_data/products/'
      'presentation/product_screen.dart',
    ).readAsStringSync();
  });

  group('Product automatic synchronization', () {
    test('defines Product Save reason', () {
      expect(
        coordinator,
        contains('productSaved'),
      );
    });

    test('defines Product status reason', () {
      expect(
        coordinator,
        contains('productStatusChanged'),
      );
    });

    test('Product form imports auto-sync', () {
      expect(
        form,
        contains(
          'master_data_auto_sync.dart',
        ),
      );
    });

    test('Product Save triggers synchronization', () {
      expect(
        form,
        contains(
          'reason: MasterDataAutoSyncReason.productSaved',
        ),
      );

      expect(
        form,
        contains(
          'MasterDataAutoSync.instance.trigger(',
        ),
      );
    });

    test('Product Save commits locally first', () {
      final int saveIndex = form.indexOf(
        '_productRepository.saveProduct',
      );

      final int syncIndex = form.indexOf(
        'MasterDataAutoSyncReason.productSaved',
      );

      expect(saveIndex, greaterThanOrEqualTo(0));
      expect(syncIndex, greaterThan(saveIndex));
    });

    test('Product screen imports auto-sync', () {
      expect(
        screen,
        contains(
          'master_data_auto_sync.dart',
        ),
      );
    });

    test('Product status triggers synchronization', () {
      expect(
        screen,
        contains(
          'reason: MasterDataAutoSyncReason.'
          'productStatusChanged',
        ),
      );
    });

    test('Product status commits locally first', () {
      final int saveIndex = screen.indexOf(
        '_repository.setProductActive',
      );

      final int syncIndex = screen.indexOf(
        'MasterDataAutoSyncReason.'
        'productStatusChanged',
      );

      expect(saveIndex, greaterThanOrEqualTo(0));
      expect(syncIndex, greaterThan(saveIndex));
    });
  });
}
