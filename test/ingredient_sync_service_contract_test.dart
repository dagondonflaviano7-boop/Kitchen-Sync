import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String serviceSource;
  late String autoSyncSource;
  late String hubSource;

  setUpAll(() {
    serviceSource = File(
      'lib/data/services/'
      'master_data_sync_service.dart',
    ).readAsStringSync();

    autoSyncSource = File(
      'lib/data/services/'
      'master_data_auto_sync.dart',
    ).readAsStringSync();

    hubSource = File(
      'lib/features/master_data/presentation/'
      'master_data_hub.dart',
    ).readAsStringSync();
  });

  group('Ingredient synchronization result', () {
    test('reports uploaded Ingredient count', () {
      expect(
        serviceSource,
        contains(
          'final int uploadedIngredients;',
        ),
      );

      expect(
        serviceSource,
        contains(
          'required this.uploadedIngredients',
        ),
      );
    });

    test('reports downloaded Ingredient count', () {
      expect(
        serviceSource,
        contains(
          'final int downloadedIngredients;',
        ),
      );

      expect(
        serviceSource,
        contains(
          'required this.downloadedIngredients',
        ),
      );
    });

    test('offline result initializes Ingredient counts', () {
      expect(
        serviceSource,
        contains(
          'uploadedIngredients = 0',
        ),
      );

      expect(
        serviceSource,
        contains(
          'downloadedIngredients = 0',
        ),
      );
    });
  });

  group('Ingredient pending upload', () {
    test('loads pending Ingredients', () {
      expect(
        serviceSource,
        contains(
          'ingredientDao.findPending(database)',
        ),
      );
    });

    test('marks Ingredient as Syncing', () {
      expect(
        serviceSource,
        contains(
          'ingredientDao.markSyncing(',
        ),
      );
    });

    test('uploads Ingredient to remote repository', () {
      expect(
        serviceSource,
        contains(
          'remoteRepository.uploadIngredient(',
        ),
      );
    });

    test('marks successful Ingredient as Synced', () {
      expect(
        serviceSource,
        contains(
          'ingredientDao.markSynced(',
        ),
      );

      expect(
        serviceSource,
        contains(
          'serverVersion: serverVersion',
        ),
      );
    });

    test('marks failed Ingredient as Error', () {
      expect(
        serviceSource,
        contains(
          'ingredientDao.markSyncError(',
        ),
      );
    });

    test('increments uploaded Ingredient count', () {
      expect(
        serviceSource,
        contains(
          'uploadedIngredients += 1',
        ),
      );
    });
  });

  group('Ingredient remote download', () {
    test('downloads Ingredients', () {
      expect(
        serviceSource,
        contains(
          'remoteRepository.downloadIngredients()',
        ),
      );
    });

    test('loads local record including tombstone', () {
      expect(
        serviceSource,
        contains(
          'ingredientDao'
          '.findByIdIncludingDeleted(',
        ),
      );
    });

    test('preserves unresolved local Ingredient', () {
      expect(
        serviceSource,
        contains(
          '_hasUnresolvedLocalIngredient(',
        ),
      );

      expect(
        serviceSource,
        contains(
          'preservedLocalChanges += 1',
        ),
      );
    });

    test('compares remote and local versions', () {
      expect(
        serviceSource,
        contains(
          '_shouldApplyRemoteIngredient(',
        ),
      );

      expect(
        serviceSource,
        contains(
          'remote.serverVersion > '
          'local.serverVersion',
        ),
      );
    });

    test('uses updated timestamp for equal versions', () {
      expect(
        serviceSource,
        contains(
          'remote.updatedAt.isAfter(',
        ),
      );
    });

    test('applies newer remote Ingredient', () {
      expect(
        serviceSource,
        contains(
          'ingredientDao.upsertRemote(',
        ),
      );
    });

    test('increments downloaded Ingredient count', () {
      expect(
        serviceSource,
        contains(
          'downloadedIngredients += 1',
        ),
      );
    });
  });

  group('Ingredient automatic synchronization', () {
    test('defines Ingredient save reason', () {
      expect(
        autoSyncSource,
        contains('ingredientSaved'),
      );
    });

    test('defines Ingredient status reason', () {
      expect(
        autoSyncSource,
        contains('ingredientStatusChanged'),
      );
    });

    test('defines Ingredient delete reason', () {
      expect(
        autoSyncSource,
        contains('ingredientDeleted'),
      );
    });

    test('logs uploaded Ingredient count', () {
      expect(
        autoSyncSource,
        contains(
          'result.uploadedIngredients',
        ),
      );
    });

    test('logs downloaded Ingredient count', () {
      expect(
        autoSyncSource,
        contains(
          'result.downloadedIngredients',
        ),
      );
    });
  });

  group('Master Data Hub Ingredient totals', () {
    test('includes Ingredients in uploaded total', () {
      expect(
        hubSource,
        contains(
          'result.uploadedIngredients',
        ),
      );
    });

    test('includes Ingredients in downloaded total', () {
      expect(
        hubSource,
        contains(
          'result.downloadedIngredients',
        ),
      );
    });

    test('mentions Ingredients on the Sync card', () {
      expect(
        hubSource,
        contains(
          "'Suppliers, Ingredients, and Recipes '",
        ),
      );
    });
  });
}
