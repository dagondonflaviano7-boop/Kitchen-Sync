import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UOM DAO and repository contracts', () {
    test('unit DAO targets units_of_measure', () {
      final String source = File(
        'lib/data/local/daos/unit_of_measure_dao.dart',
      ).readAsStringSync();

      expect(
        source.contains("'units_of_measure'"),
        isTrue,
      );
      expect(
        source.contains('codeExists'),
        isTrue,
      );
      expect(
        source.contains('ConflictAlgorithm.replace'),
        isTrue,
      );
    });

    test('conversion DAO targets unit_conversions', () {
      final String source = File(
        'lib/data/local/daos/unit_conversion_dao.dart',
      ).readAsStringSync();

      expect(
        source.contains("'unit_conversions'"),
        isTrue,
      );
      expect(
        source.contains("'UNIVERSAL'"),
        isTrue,
      );
    });

    test('repository seeds units before conversions', () {
      final String source = File(
        'lib/data/repositories/'
        'unit_of_measure_repository.dart',
      ).readAsStringSync();

      final int unitSave = source.indexOf(
        'unitDao.upsertAll',
      );
      final int conversionSave = source.indexOf(
        'conversionDao.upsertAll',
      );

      expect(unitSave, greaterThanOrEqualTo(0));
      expect(conversionSave, greaterThan(unitSave));
    });

    test('repository detects duplicate unit codes', () {
      final String source = File(
        'lib/data/repositories/'
        'unit_of_measure_repository.dart',
      ).readAsStringSync();

      expect(
        source.contains('unitDao.codeExists'),
        isTrue,
      );
      expect(
        source.contains('already exists'),
        isTrue,
      );
    });

    test('repository supports reverse conversion', () {
      final String source = File(
        'lib/data/repositories/'
        'unit_of_measure_repository.dart',
      ).readAsStringSync();

      expect(
        source.contains(
          'quantity / reverse.conversionFactor',
        ),
        isTrue,
      );
    });

    test('repository does not treat packaging as universal', () {
      final String source = File(
        'lib/data/repositories/'
        'unit_of_measure_repository.dart',
      ).readAsStringSync();

      expect(
        source.contains(
          'No active universal conversion exists',
        ),
        isTrue,
      );
    });
  });
}
