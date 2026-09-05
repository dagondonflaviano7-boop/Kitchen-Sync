import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/products/'
      'presentation/product_screen.dart',
    ).readAsStringSync();
  });

  group('Product synchronization UI', () {
    test('imports shared synchronization status', () {
      expect(
        source,
        contains(
          'models/unit_of_measure.dart',
        ),
      );
    });

    test('provides Product sync badge', () {
      expect(
        source,
        contains(
          'Widget _buildSyncBadge(',
        ),
      );

      expect(
        source,
        contains(
          'switch (product.syncStatus)',
        ),
      );
    });

    test('supports Pending state', () {
      expect(
        source,
        contains(
          'MasterSyncStatus.pending',
        ),
      );

      expect(source, contains("'Pending'"));
      expect(
        source,
        contains('Icons.schedule_outlined'),
      );
    });

    test('supports Syncing state', () {
      expect(
        source,
        contains(
          'MasterSyncStatus.syncing',
        ),
      );

      expect(source, contains("'Syncing'"));
      expect(source, contains('Icons.sync'));
    });

    test('supports Synced state', () {
      expect(
        source,
        contains(
          'MasterSyncStatus.synced',
        ),
      );

      expect(source, contains("'Synced'"));

      expect(
        source,
        contains(
          'Icons.cloud_done_outlined',
        ),
      );
    });

    test('supports Error state', () {
      expect(
        source,
        contains(
          'MasterSyncStatus.error',
        ),
      );

      expect(source, contains("'Error'"));

      expect(
        source,
        contains(
          'Icons.cloud_off_outlined',
        ),
      );
    });

    test('shows sync state on Product cards', () {
      expect(
        source,
        contains(
          '_buildSyncBadge(product)',
        ),
      );
    });

    test('uses accessible text and icons', () {
      expect(
        source,
        contains('Text('),
      );

      expect(
        source,
        contains('Icon('),
      );
    });
  });
}
