import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v3.dart';

void main() {
  group('Migration V3 contract', () {
    final String sql = migrationV3.join(' ');

    test('creates units of measure', () {
      expect(
        sql.contains(
          'CREATE TABLE IF NOT EXISTS units_of_measure',
        ),
        isTrue,
      );
    });

    test('creates universal unit conversions', () {
      expect(
        sql.contains(
          'CREATE TABLE IF NOT EXISTS unit_conversions',
        ),
        isTrue,
      );
      expect(
        sql.contains("'UNIVERSAL', 'ITEM_SPECIFIC'"),
        isTrue,
      );
    });

    test('creates product packaging conversions', () {
      expect(
        sql.contains(
          'CREATE TABLE IF NOT EXISTS '
          'product_packaging_conversions',
        ),
        isTrue,
      );
    });

    test('supports controlled unit types', () {
      for (final String type in <String>[
        'COUNT',
        'WEIGHT',
        'VOLUME',
        'PACKAGING',
      ]) {
        expect(
          sql.contains(type),
          isTrue,
          reason: 'Missing unit type: $type',
        );
      }
    });

    test('prevents same-unit conversions', () {
      expect(
        sql.contains(
          'CHECK(source_unit_code != target_unit_code)',
        ),
        isTrue,
      );
    });

    test('extends the existing supplier table', () {
      expect(
        sql.contains('ALTER TABLE suppliers'),
        isTrue,
      );
      expect(
        sql.contains('ADD COLUMN contact_person'),
        isTrue,
      );
      expect(
        sql.contains('ADD COLUMN lead_time_days'),
        isTrue,
      );
      expect(
        sql.contains('ADD COLUMN sync_status'),
        isTrue,
      );
    });

    test('does not recreate the supplier table', () {
      expect(
        sql.contains(
          'CREATE TABLE IF NOT EXISTS suppliers',
        ),
        isFalse,
      );
    });
  });
}
