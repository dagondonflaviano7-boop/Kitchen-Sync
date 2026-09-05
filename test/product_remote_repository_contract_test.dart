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

  group('Product Firebase remote repository', () {
    test('imports Product model', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/"
          "domain/models/product.dart';",
        ),
      );
    });

    test('defines Products Firebase node', () {
      expect(
        source,
        contains(
          "productsNode = 'products'",
        ),
      );
    });

    test('provides Product upload', () {
      expect(
        source,
        contains(
          'Future<int> uploadProduct(',
        ),
      );

      expect(
        source,
        contains(
          'Product product',
        ),
      );
    });

    test('validates Product before upload', () {
      expect(
        source,
        contains(
          'product.validate()',
        ),
      );
    });

    test('uploads to Product ID node', () {
      expect(
        source,
        contains(
          r"'$productsNode/${product.id}'",
        ),
      );
    });

    test('calculates next Product version', () {
      expect(
        source,
        contains(
          'localVersion: '
          'product.serverVersion',
        ),
      );

      expect(
        source,
        contains(
          'final int nextVersion',
        ),
      );
    });

    test('serializes Product payload', () {
      expect(
        source,
        contains(
          'product.toFirebase()',
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
          "payload['serverVersion'] = "
          "nextVersion",
        ),
      );
    });

    test('writes Product payload', () {
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

    test('handles Product upload timeout', () {
      expect(
        source,
        contains(
          'Product synchronization timed out.',
        ),
      );
    });

    test('handles Product upload rejection', () {
      expect(
        source,
        contains(
          'Firebase rejected the '
          'Product update.',
        ),
      );
    });

    test('provides Product download', () {
      expect(
        source,
        contains(
          'Future<List<Product>> '
          'downloadProducts() async',
        ),
      );
    });

    test('downloads Products collection', () {
      expect(
        source,
        contains(
          '.ref(productsNode)',
        ),
      );

      expect(
        source,
        contains(
          '.get()',
        ),
      );
    });

    test('returns empty list when unavailable', () {
      expect(
        source,
        contains(
          'return const <Product>[];',
        ),
      );
    });

    test('requires collection map format', () {
      expect(
        source,
        contains(
          '_requireMap(snapshot.value)',
        ),
      );
    });

    test('skips non-map records', () {
      expect(
        source,
        contains(
          'if (value is! Map)',
        ),
      );

      expect(
        source,
        contains('continue;'),
      );
    });

    test('isolates malformed Product records', () {
      expect(
        source,
        contains(
          'on FormatException catch',
        ),
      );

      expect(
        source,
        contains(
          'Skipping malformed '
          'Firebase Product',
        ),
      );
    });

    test('deserializes Product records', () {
      expect(
        source,
        contains(
          'Product.fromFirebase(',
        ),
      );

      expect(
        source,
        contains(
          'entry.key.toString()',
        ),
      );
    });

    test('sorts downloaded Products', () {
      expect(
        source,
        contains(
          'products.sort(',
        ),
      );

      expect(
        source,
        contains(
          'first.productName',
        ),
      );

      expect(
        source,
        contains(
          'first.sku.compareTo(second.sku)',
        ),
      );
    });

    test('returns unmodifiable Product list', () {
      expect(
        source,
        contains(
          'List<Product>.unmodifiable(',
        ),
      );
    });

    test('handles Product download timeout', () {
      expect(
        source,
        contains(
          'Downloading Products timed out.',
        ),
      );
    });

    test('handles Product download error', () {
      expect(
        source,
        contains(
          'Unable to download Products ',
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
