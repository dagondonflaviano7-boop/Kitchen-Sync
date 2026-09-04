import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/local/daos/recipe_dao.dart',
    ).readAsStringSync();
  });

  group('Recipe DAO synchronization contract', () {
    test('provides pending Recipe query', () {
      expect(
        source,
        contains(
          'Future<List<Recipe>> findPending(',
        ),
      );

      expect(
        source,
        contains(
          'sync_status IN (?, ?)',
        ),
      );

      expect(source, contains("'PENDING'"));
      expect(source, contains("'ERROR'"));
    });

    test('validates pending query limit', () {
      expect(
        RegExp(
          r"Pending synchronization limit\s*"
          r"'\s*'must be greater than zero\.",
        ).hasMatch(source),
        isTrue,
      );
    });

    test('pending query includes tombstones', () {
      final int start = source.indexOf(
        'Future<List<Recipe>> findPending(',
      );

      final int end = source.indexOf(
        'Future<void> markSyncing(',
        start,
      );

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      final String pendingSection = source.substring(start, end);

      expect(
        pendingSection,
        isNot(
          contains('deleted_at IS NULL'),
        ),
      );
    });

    test('pending Recipes include Ingredient lines', () {
      expect(
        source,
        contains(
          '_getIngredientsByRecipeId(',
        ),
      );

      expect(
        source,
        contains(
          'recipe.copyWith(',
        ),
      );

      expect(
        source,
        contains(
          'ingredients: ingredients',
        ),
      );
    });

    test('provides mark Syncing operation', () {
      expect(
        source,
        contains(
          'Future<void> markSyncing(',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.syncing',
        ),
      );
    });

    test('provides mark Synced operation', () {
      expect(
        source,
        contains(
          'Future<void> markSynced(',
        ),
      );

      expect(
        source,
        contains(
          "'sync_status': 'SYNCED'",
        ),
      );

      expect(
        source,
        contains(
          "'server_version': serverVersion",
        ),
      );
    });

    test('rejects negative server version', () {
      expect(
        source,
        contains(
          'Server version must be zero or greater.',
        ),
      );
    });

    test('provides mark Error operation', () {
      expect(
        source,
        contains(
          'Future<void> markSyncError(',
        ),
      );

      expect(
        source,
        contains(
          'MasterSyncStatus.error',
        ),
      );
    });

    test('throws when Recipe is missing', () {
      expect(
        source,
        contains(
          'The Recipe record was not found.',
        ),
      );
    });

    test('provides atomic remote upsert', () {
      expect(
        source,
        contains(
          'Future<void> upsertRemote(',
        ),
      );

      expect(
        source,
        contains(
          'database.transaction(',
        ),
      );
    });

    test('remote upsert marks Recipe Synced', () {
      expect(
        source,
        contains(
          'syncStatus: MasterSyncStatus.synced',
        ),
      );
    });

    test('remote upsert replaces Recipe header', () {
      expect(
        RegExp(
          r"transaction\.insert\s*\(\s*"
          r"'recipe_master'",
        ).hasMatch(source),
        isTrue,
      );

      expect(
        source,
        contains(
          'ConflictAlgorithm.replace',
        ),
      );
    });

    test('remote upsert replaces Ingredient lines', () {
      expect(
        RegExp(
          r"transaction\.delete\s*\(\s*"
          r"'recipe_ingredients'",
        ).hasMatch(source),
        isTrue,
      );

      expect(
        RegExp(
          r"transaction\.insert\s*\(\s*"
          r"'recipe_ingredients'",
        ).hasMatch(source),
        isTrue,
      );
    });

    test('remote Ingredient lines use Recipe ID', () {
      expect(
        source,
        contains(
          'ingredient.copyWith(',
        ),
      );

      expect(
        source,
        contains(
          'recipeId: synchronized.id',
        ),
      );
    });
  });
}
