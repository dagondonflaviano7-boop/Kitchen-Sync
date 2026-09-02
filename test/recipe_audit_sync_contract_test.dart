import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String recipeSource;
  late String daoSource;

  setUpAll(() {
    recipeSource = File(
      'lib/domain/models/recipe.dart',
    ).readAsStringSync();

    daoSource = File(
      'lib/data/local/daos/recipe_dao.dart',
    ).readAsStringSync();
  });

  group('Recipe audit and synchronization model', () {
    test('contains Recipe audit fields', () {
      expect(
        recipeSource,
        contains('final DateTime createdAt'),
      );

      expect(
        recipeSource,
        contains('final DateTime updatedAt'),
      );

      expect(
        recipeSource,
        contains('final String? createdBy'),
      );

      expect(
        recipeSource,
        contains('final String? updatedBy'),
      );
    });

    test('contains Recipe synchronization fields', () {
      expect(
        recipeSource,
        contains(
          'final MasterSyncStatus syncStatus',
        ),
      );

      expect(
        recipeSource,
        contains('final int serverVersion'),
      );
    });

    test('contains soft-delete metadata', () {
      expect(
        recipeSource,
        contains('final DateTime? deletedAt'),
      );

      expect(
        recipeSource,
        contains('bool get isDeleted'),
      );
    });

    test('serializes audit values to SQLite', () {
      for (final String column in <String>[
        "'created_at'",
        "'updated_at'",
        "'created_by'",
        "'updated_by'",
        "'sync_status'",
        "'server_version'",
        "'deleted_at'",
      ]) {
        expect(
          recipeSource,
          contains(column),
        );
      }
    });

    test('parses audit values from SQLite', () {
      expect(
        recipeSource,
        contains(
          'masterSyncStatusFromStorage(',
        ),
      );

      expect(
        recipeSource,
        contains(
          'DateTime.tryParse(',
        ),
      );
    });

    test('copyWith preserves audit fields', () {
      final int copyWithPosition = recipeSource.indexOf(
        'Recipe copyWith(',
      );

      expect(
        copyWithPosition,
        greaterThanOrEqualTo(0),
      );

      final String copyWithSource = recipeSource.substring(
        copyWithPosition,
      );

      for (final String field in <String>[
        'createdAt',
        'updatedAt',
        'createdBy',
        'updatedBy',
        'syncStatus',
        'serverVersion',
        'deletedAt',
      ]) {
        expect(
          copyWithSource,
          contains(field),
        );
      }
    });

    test('DAO excludes deleted Recipes from reads', () {
      expect(
        daoSource,
        contains(
          'deleted_at IS NULL',
        ),
      );
    });

    test('DAO implements softDelete', () {
      expect(
        daoSource,
        contains(
          'Future<void> softDelete(',
        ),
      );

      expect(
        daoSource,
        contains(
          "'sync_status': 'PENDING'",
        ),
      );
    });

    test('physical delete is not the normal delete path', () {
      final int deletePosition = daoSource.indexOf(
        'Future<void> deleteRecipe(',
      );

      final int nextMethodPosition = daoSource.indexOf(
        'Future<Recipe?> getRecipeById(',
        deletePosition,
      );

      expect(
        deletePosition,
        greaterThanOrEqualTo(0),
      );

      expect(
        nextMethodPosition,
        greaterThan(deletePosition),
      );

      final String method = daoSource.substring(
        deletePosition,
        nextMethodPosition,
      );

      expect(
        method,
        isNot(contains('database.delete(')),
      );
    });
  });
}
