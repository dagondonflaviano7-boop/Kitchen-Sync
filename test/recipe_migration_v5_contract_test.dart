import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v5.dart';

void main() {
  late String sql;

  setUpAll(() {
    sql = migrationV5.join('\n');
  });

  group('Recipe Migration V5', () {
    test('uses database version 5', () {
      expect(
        AppConstants.databaseVersion,
        5,
      );
    });

    test('creates Recipe Master table', () {
      expect(
        sql,
        contains(
          'CREATE TABLE IF NOT EXISTS '
          'recipe_master',
        ),
      );
    });

    test('creates Recipe Ingredients table', () {
      expect(
        sql,
        contains(
          'CREATE TABLE IF NOT EXISTS '
          'recipe_ingredients',
        ),
      );
    });

    test('requires positive Recipe yield', () {
      expect(
        sql,
        contains(
          'CHECK(yield_quantity > 0)',
        ),
      );
    });

    test('requires positive Ingredient quantity', () {
      expect(
        sql,
        contains(
          'CHECK(quantity_required > 0)',
        ),
      );
    });

    test('allows zero Ingredient cost', () {
      expect(
        sql,
        contains(
          'CHECK(cost_per_usage_unit >= 0)',
        ),
      );
    });

    test('links lines to Recipe header', () {
      expect(
        sql,
        contains(
          'REFERENCES recipe_master(id)',
        ),
      );

      expect(
        sql,
        contains('ON DELETE CASCADE'),
      );
    });

    test('links lines to Ingredient Master', () {
      expect(
        sql,
        contains(
          'REFERENCES ingredients(id)',
        ),
      );
    });

    test('preserves unique Recipe codes', () {
      expect(
        sql,
        contains(
          'recipe_code TEXT NOT NULL UNIQUE',
        ),
      );
    });

    test('creates Recipe indexes', () {
      expect(
        sql,
        contains('idx_recipe_master_code'),
      );

      expect(
        sql,
        contains('idx_recipe_master_name'),
      );

      expect(
        sql,
        contains(
          'idx_recipe_ingredients_recipe',
        ),
      );
    });

    test('does not modify legacy Recipe tables', () {
      expect(
        sql,
        isNot(
          contains('ALTER TABLE recipes'),
        ),
      );

      expect(
        sql,
        isNot(
          contains('DROP TABLE recipes'),
        ),
      );

      expect(
        sql,
        isNot(
          contains('DROP TABLE recipe_items'),
        ),
      );
    });
  });
}
