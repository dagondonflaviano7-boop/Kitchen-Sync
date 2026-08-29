import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Master Data remote repository contract', () {
    late String source;
    late String rules;

    setUpAll(() {
      source = File(
        'lib/data/remote/'
        'master_data_remote_repository.dart',
      ).readAsStringSync();

      rules = File(
        'firebase/database.rules.json',
      ).readAsStringSync();
    });

    test('uses dedicated Firebase nodes', () {
      expect(
        source.contains(
          "unitsNode = 'unitsOfMeasure'",
        ),
        isTrue,
      );

      expect(
        source.contains(
          "suppliersNode = 'suppliers'",
        ),
        isTrue,
      );
    });

    test('supports Unit upload and download', () {
      expect(
        source.contains('uploadUnit'),
        isTrue,
      );

      expect(
        source.contains('downloadUnits'),
        isTrue,
      );

      expect(
        source.contains(
          'UnitOfMeasure.fromFirebase',
        ),
        isTrue,
      );
    });

    test('supports Supplier upload and download', () {
      expect(
        source.contains('uploadSupplier'),
        isTrue,
      );

      expect(
        source.contains('downloadSuppliers'),
        isTrue,
      );

      expect(
        source.contains(
          'Supplier.fromFirebase',
        ),
        isTrue,
      );
    });

    test('uses set for remote upsert', () {
      expect(
        source.contains('.set(payload)'),
        isTrue,
      );
    });

    test('does not physically remove tombstones', () {
      expect(
        source.contains('.remove()'),
        isFalse,
      );
    });

    test('does not upload local sync status', () {
      expect(
        source.contains(
          "payload.remove('syncStatus')",
        ),
        isTrue,
      );
    });

    test('increments server versions', () {
      expect(
        source.contains('_nextServerVersion'),
        isTrue,
      );

      expect(
        source.contains('highestVersion + 1'),
        isTrue,
      );
    });

    test('applies request timeouts', () {
      expect(
        source.contains(
          'Duration(seconds: 15)',
        ),
        isTrue,
      );

      expect(
        source.contains('.timeout(requestTimeout)'),
        isTrue,
      );
    });

    test('rules allow Units master data', () {
      expect(
        rules.contains('"unitsOfMeasure"'),
        isTrue,
      );

      expect(
        rules.contains("'serverVersion'"),
        isTrue,
      );
    });

    test('rules allow Supplier master data', () {
      expect(
        rules.contains('"suppliers"'),
        isTrue,
      );

      expect(
        rules.contains("'supplierCode'"),
        isTrue,
      );
    });
  });
}
