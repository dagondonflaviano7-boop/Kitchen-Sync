import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/services/master_data_sync_service.dart',
    ).readAsStringSync();
  });

  group('Recipe Sync Service contract', () {
    test('imports Recipe model', () {
      expect(
        source.contains(
          "import 'package:kitchen_sync/domain/models/recipe.dart';",
        ),
        isTrue,
      );
    });

    test('imports RecipeDao', () {
      expect(
        source.contains(
          "import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';",
        ),
        isTrue,
      );
    });

    test('contains recipe dao field', () {
      expect(
        source.contains(
          'final RecipeDao recipeDao;',
        ),
        isTrue,
      );
    });

    test('uploads pending recipes', () {
      expect(
        source.contains(
          'await recipeDao.findPending',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'uploadRecipe(',
        ),
        isTrue,
      );
    });

    test('handles recipe sync lifecycle', () {
      expect(
        source.contains(
          'recipeDao.markSyncing',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'recipeDao.markSynced',
        ),
        isTrue,
      );

      expect(
        source.contains(
          'recipeDao.markSyncError',
        ),
        isTrue,
      );
    });

    test('downloads remote recipes', () {
      expect(
        source.contains(
          'downloadRecipes()',
        ),
        isTrue,
      );
    });

    test('applies remote recipe updates', () {
      expect(
        source.contains(
          'recipeDao.upsertRemote',
        ),
        isTrue,
      );
    });

    test('contains recipe conflict protection', () {
      expect(
        source.contains(
          '_hasUnresolvedLocalRecipe',
        ),
        isTrue,
      );

      expect(
        source.contains(
          '_shouldApplyRemoteRecipe',
        ),
        isTrue,
      );
    });
  });
}
