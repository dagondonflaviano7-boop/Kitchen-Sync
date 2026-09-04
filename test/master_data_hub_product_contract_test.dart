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

  group('Master Data Hub Product integration', () {
    test('imports Product Screen', () {
      expect(
        source,
        contains(
          'products/presentation/'
          'product_screen.dart',
        ),
      );
    });

    test('provides Product Master card', () {
      expect(
        source,
        contains(
          "title: 'Product Master'",
        ),
      );

      expect(
        source,
        contains(
          'Manage selling prices, '
          'inventory modes, ',
        ),
      );
    });

    test('opens Product Screen', () {
      expect(
        source,
        contains(
          'const ProductScreen()',
        ),
      );

      expect(
        source,
        contains(
          'MaterialPageRoute<void>',
        ),
      );
    });

    test('keeps Product Master enabled', () {
      final int titleIndex = source.indexOf(
        "title: 'Product Master'",
      );

      expect(titleIndex, greaterThanOrEqualTo(0));

      final String productCard = source.substring(
        titleIndex,
        titleIndex + 700,
      );

      expect(
        productCard,
        contains('enabled: true'),
      );
    });
  });
}
