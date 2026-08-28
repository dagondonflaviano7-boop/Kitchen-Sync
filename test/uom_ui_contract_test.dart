import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Units of Measure interface contract', () {
    late String unitScreen;
    late String masterDataHub;
    late String adaptiveShell;

    setUpAll(() {
      unitScreen = File(
        'lib/features/master_data/units/presentation/'
        'unit_of_measure_screen.dart',
      ).readAsStringSync();

      masterDataHub = File(
        'lib/features/master_data/presentation/'
        'master_data_hub.dart',
      ).readAsStringSync();

      adaptiveShell = File(
        'lib/features/dashboard/presentation/'
        'adaptive_shell.dart',
      ).readAsStringSync();
    });

    test('More opens the Master Data Hub', () {
      expect(
        adaptiveShell.contains(
          "master_data_hub.dart",
        ),
        isTrue,
      );

      expect(
        adaptiveShell.contains(
          'page: MasterDataHub()',
        ),
        isTrue,
      );
    });

    test('Master Data Hub opens Units of Measure', () {
      expect(
        masterDataHub.contains(
          'UnitOfMeasureScreen',
        ),
        isTrue,
      );

      expect(
        masterDataHub.contains(
          "'Units of Measure'",
        ),
        isTrue,
      );
    });

    test('Suppliers are marked as the next module', () {
      expect(
        masterDataHub.contains("'Suppliers'"),
        isTrue,
      );

      expect(
        masterDataHub.contains("'COMING NEXT'"),
        isTrue,
      );
    });

    test('UOM screen seeds missing standard units', () {
      expect(
        unitScreen.contains(
          '_repository.seedStandardUnits()',
        ),
        isTrue,
      );
    });

    test('UOM screen supports local search', () {
      expect(
        unitScreen.contains(
          '_repository.searchUnits',
        ),
        isTrue,
      );

      expect(
        unitScreen.contains(
          'Search unit code or name',
        ),
        isTrue,
      );
    });

    test('UOM screen supports status filtering', () {
      for (final String status in <String>[
        'UnitStatusFilter.all',
        'UnitStatusFilter.active',
        'UnitStatusFilter.inactive',
      ]) {
        expect(
          unitScreen.contains(status),
          isTrue,
          reason: 'Missing UOM status filter: $status',
        );
      }
    });

    test('UOM screen supports type filtering', () {
      for (final String type in <String>[
        'UnitType.count',
        'UnitType.weight',
        'UnitType.volume',
        'UnitType.packaging',
      ]) {
        expect(
          unitScreen.contains(type),
          isTrue,
          reason: 'Missing UOM type filter: $type',
        );
      }
    });

    test('UOM screen supports activation changes', () {
      expect(
        unitScreen.contains(
          '_repository.setUnitActive',
        ),
        isTrue,
      );

      expect(
        unitScreen.contains("'Deactivate'"),
        isTrue,
      );

      expect(
        unitScreen.contains("'Activate'"),
        isTrue,
      );
    });

    test('UOM screen has phone and tablet layouts', () {
      expect(
        unitScreen.contains(
          'constraints.maxWidth >= 760',
        ),
        isTrue,
      );

      expect(
        unitScreen.contains('_UnitCard'),
        isTrue,
      );

      expect(
        unitScreen.contains('_UnitTable'),
        isTrue,
      );
    });
  });
}
