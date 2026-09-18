import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/presentation/'
      'master_data_hub.dart',
    ).readAsStringSync();
  });

  group('Default Master Data seed action', () {
    test('imports the seed service', () {
      expect(
        source,
        contains(
          'default_master_data_seed_service.dart',
        ),
      );
    });

    test('owns one seed service', () {
      expect(
        source,
        contains(
          'final DefaultMasterDataSeedService '
          '_seedService',
        ),
      );
    });

    test('prevents overlapping operations', () {
      expect(
        source,
        contains('if (_seeding || _syncing)'),
      );

      expect(
        source,
        contains('enabled: !_seeding && !_syncing'),
      );
    });

    test('requires explicit confirmation', () {
      expect(
        source,
        contains('showDialog<bool>'),
      );

      expect(
        source,
        contains("'Load 100 Default Records?'"),
      );

      expect(
        source,
        contains("'Load Records'"),
      );
    });

    test('shows the exact distribution', () {
      for (final String value in <String>[
        '10 Units of Measure',
        '10 Suppliers',
        '40 Ingredients',
        '15 Recipes',
        '25 Products',
      ]) {
        expect(source, contains(value));
      }
    });

    test('passes the authenticated user', () {
      expect(
        source,
        contains(
          'currentUserId: widget.currentUserId',
        ),
      );
    });

    test('shows created and skipped totals', () {
      expect(
        source,
        contains('result.createdTotal'),
      );

      expect(
        source,
        contains('result.skippedTotal'),
      );
    });

    test('shows module-level results', () {
      for (final String value in <String>[
        'result.createdUnits',
        'result.createdSuppliers',
        'result.createdIngredients',
        'result.createdRecipes',
        'result.createdProducts',
      ]) {
        expect(source, contains(value));
      }
    });

    test('shows Firebase request status', () {
      expect(
        source,
        contains(
          'result.synchronizationRequested',
        ),
      );
    });

    test('does not run from initState', () {
      final int method = source.indexOf(
        'Future<void> _loadDefaultMasterData',
      );

      final int button = source.indexOf(
        'onTap: _loadDefaultMasterData',
      );

      expect(method, greaterThanOrEqualTo(0));
      expect(button, greaterThan(method));
    });
  });
}
