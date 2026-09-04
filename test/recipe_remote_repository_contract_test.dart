import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/remote/master_data_remote_repository.dart',
    ).readAsStringSync();
  });

  group('Recipe Firebase remote repository', () {
    test('imports Recipe model', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/domain/models/recipe.dart';",
        ),
      );
    });

    test('defines Recipe Firebase node', () {
      expect(
        source,
        contains(
          "recipesNode = 'recipes'",
        ),
      );
    });

    test('provides Recipe upload', () {
      expect(
        source,
        contains(
          'Future<int> uploadRecipe(',
        ),
      );

      expect(
        source,
        contains(
          'Recipe recipe',
        ),
      );
    });

    test('validates Recipe before upload', () {
      expect(
        source,
        contains(
          'recipe.validate()',
        ),
      );
    });

    test('uploads to Recipe ID node', () {
      expect(
        source,
        contains(
          r"'$recipesNode/${recipe.id}'",
        ),
      );
    });

    test('uses Recipe Firebase serialization', () {
      expect(
        source,
        contains(
          'recipe.toFirebase()',
        ),
      );
    });

    test('removes local sync status', () {
      expect(
        source,
        contains(
          "payload.remove('syncStatus')",
        ),
      );
    });

    test('stores next server version', () {
      expect(
        source,
        contains(
          "payload['serverVersion'] = nextVersion",
        ),
      );
    });

    test('writes Recipe payload to Firebase', () {
      expect(
        source,
        contains(
          '.set(payload)',
        ),
      );
    });

    test('provides Recipe timeout handling', () {
      expect(
        source,
        contains(
          'Recipe synchronization timed out.',
        ),
      );
    });

    test('provides Recipe Firebase rejection handling', () {
      expect(
        source,
        contains(
          'Firebase rejected the Recipe update.',
        ),
      );
    });

    test('provides Recipe download', () {
      expect(
        source,
        contains(
          'Future<List<Recipe>> downloadRecipes() async',
        ),
      );
    });

    test('uses Recipe Firebase deserialization', () {
      expect(
        source,
        contains(
          'Recipe.fromFirebase(',
        ),
      );
    });

    test('returns unmodifiable Recipe list', () {
      expect(
        source,
        contains(
          'List<Recipe>.unmodifiable(',
        ),
      );
    });
  });
}
