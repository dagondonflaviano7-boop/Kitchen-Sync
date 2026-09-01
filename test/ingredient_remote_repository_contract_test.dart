import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/remote/'
      'master_data_remote_repository.dart',
    ).readAsStringSync();
  });

  group('Ingredient Firebase remote repository', () {
    test('imports the Ingredient model', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/"
          "domain/models/ingredient.dart';",
        ),
      );
    });

    test('defines the Ingredients Firebase node', () {
      expect(
        source,
        contains(
          "ingredientsNode = 'ingredients'",
        ),
      );
    });

    test('provides Ingredient upload', () {
      expect(
        source,
        contains(
          'Future<int> uploadIngredient(',
        ),
      );

      expect(
        source,
        contains(
          'Ingredient ingredient',
        ),
      );
    });

    test('validates Ingredient before upload', () {
      expect(
        source,
        contains(
          'ingredient.validate()',
        ),
      );
    });

    test('uploads to the Ingredient ID node', () {
      expect(
        source,
        contains(
          r"'$ingredientsNode/${ingredient.id}'",
        ),
      );
    });

    test('calculates the next server version', () {
      expect(
        source,
        contains(
          'localVersion: ingredient.serverVersion',
        ),
      );

      expect(
        source,
        contains(
          'final int nextVersion',
        ),
      );
    });

    test('serializes the Ingredient payload', () {
      expect(
        source,
        contains(
          'ingredient.toFirebase()',
        ),
      );
    });

    test('removes local sync status from upload payload', () {
      expect(
        source,
        contains(
          "payload.remove('syncStatus')",
        ),
      );
    });

    test('stores the next server version in payload', () {
      expect(
        source,
        contains(
          "payload['serverVersion'] = nextVersion",
        ),
      );
    });

    test('writes Ingredient payload to Firebase', () {
      expect(
        source,
        contains(
          '.set(payload)',
        ),
      );

      expect(
        source,
        contains(
          '.timeout(requestTimeout)',
        ),
      );
    });

    test('provides Ingredient upload timeout error', () {
      expect(
        source,
        contains(
          'Ingredient synchronization timed out.',
        ),
      );
    });

    test('provides Ingredient Firebase rejection error', () {
      expect(
        source,
        contains(
          'Firebase rejected the Ingredient update.',
        ),
      );
    });

    test('provides Ingredient download', () {
      expect(
        source,
        contains(
          'Future<List<Ingredient>> '
          'downloadIngredients() async',
        ),
      );
    });

    test('downloads from the Ingredients collection', () {
      expect(
        source,
        contains(
          '.ref(ingredientsNode)',
        ),
      );

      expect(
        source,
        contains(
          '.get()',
        ),
      );
    });

    test('returns an empty list when no records exist', () {
      expect(
        source,
        contains(
          'return const <Ingredient>[];',
        ),
      );
    });

    test('requires Firebase collection map format', () {
      expect(
        source,
        contains(
          '_requireMap(snapshot.value)',
        ),
      );
    });

    test('skips malformed non-map child records', () {
      expect(
        source,
        contains(
          'if (value is! Map)',
        ),
      );

      expect(
        source,
        contains(
          'continue;',
        ),
      );
    });

    test('parses downloaded Ingredient records', () {
      expect(
        source,
        contains(
          'Ingredient.fromFirebase(',
        ),
      );

      expect(
        source,
        contains(
          'entry.key.toString()',
        ),
      );
    });

    test('returns an unmodifiable Ingredient list', () {
      expect(
        source,
        contains(
          'List<Ingredient>.unmodifiable(',
        ),
      );
    });

    test('provides Ingredient download timeout error', () {
      expect(
        source,
        contains(
          'Downloading Ingredients timed out.',
        ),
      );
    });

    test('provides Ingredient download Firebase error', () {
      expect(
        source,
        contains(
          'Unable to download Ingredients ',
        ),
      );

      expect(
        source,
        contains(
          'from Firebase.',
        ),
      );
    });
  });
}
