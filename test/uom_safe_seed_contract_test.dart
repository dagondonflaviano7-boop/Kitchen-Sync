import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Safe standard UOM seeding', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/data/repositories/'
        'unit_of_measure_repository.dart',
      ).readAsStringSync();
    });

    test('checks for an existing unit by code', () {
      expect(
        source.contains('unitDao.findByCode'),
        isTrue,
      );
    });

    test('checks for an existing conversion by id', () {
      expect(
        source.contains('conversionDao.findById'),
        isTrue,
      );
    });

    test('inserts only missing records', () {
      expect(
        source.contains('if (existing == null)'),
        isTrue,
      );
    });

    test('does not bulk replace standard records', () {
      expect(
        source.contains(
          'unitDao.upsertAll(',
        ),
        isFalse,
      );
      expect(
        source.contains(
          'conversionDao.upsertAll(',
        ),
        isFalse,
      );
    });

    test('saves units before conversions', () {
      final int unitSave = source.indexOf(
        'unitDao.upsert(',
      );
      final int conversionSave = source.indexOf(
        'conversionDao.upsert(',
      );

      expect(unitSave, greaterThanOrEqualTo(0));
      expect(conversionSave, greaterThan(unitSave));
    });
  });
}
