import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/domain/models/recipe.dart',
    ).readAsStringSync();
  });

  group('Recipe Persistence Contract', () {
    test('contains validate', () {
      expect(
        source,
        contains('validate('),
      );
    });

    test('contains toSqlite', () {
      expect(
        source,
        contains('toSqlite('),
      );
    });

    test('contains fromSqlite', () {
      expect(
        source,
        contains('fromSqlite('),
      );
    });

    test('contains copyWith', () {
      expect(
        source,
        contains('copyWith('),
      );
    });
  });
}
