import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/master_data/presentation/'
      'master_data_hub.dart',
    ).readAsStringSync();
  });

  group('Master Data Hub Recipe sync UI', () {
    test('includes uploaded Recipe count', () {
      expect(
        source,
        contains(
          'result.uploadedRecipes',
        ),
      );
    });

    test('includes downloaded Recipe count', () {
      expect(
        source,
        contains(
          'result.downloadedRecipes',
        ),
      );
    });

    test('includes Recipes in Sync card', () {
      expect(
        source,
        contains(
          'Ingredients, Recipes, ',
        ),
      );

      expect(
        source,
        contains(
          "'and Products with Firebase.'",
        ),
      );
    });

    test('keeps upload and download totals', () {
      expect(
        source,
        contains(
          'final int uploaded',
        ),
      );

      expect(
        source,
        contains(
          'final int downloaded',
        ),
      );
    });

    test('keeps synchronization success message', () {
      expect(
        source,
        contains(
          'Master data synchronized successfully.',
        ),
      );

      expect(
        source,
        contains(
          r'$uploaded uploaded',
        ),
      );

      expect(
        source,
        contains(
          r'$downloaded downloaded',
        ),
      );
    });
  });
}
