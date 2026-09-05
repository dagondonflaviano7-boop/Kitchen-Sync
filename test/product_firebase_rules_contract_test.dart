import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;
  late Map<String, dynamic> decoded;

  setUpAll(() {
    rules = File(
      'firebase/database.rules.json',
    ).readAsStringSync();

    decoded = jsonDecode(rules) as Map<String, dynamic>;
  });

  group('Product Firebase rules', () {
    test('rules file remains valid JSON', () {
      expect(decoded, isNotEmpty);
    });

    test('defines Product collection', () {
      expect(
        rules,
        contains('"products"'),
      );

      expect(
        rules,
        contains('"\$productId"'),
      );
    });

    test('requires active authenticated access', () {
      expect(
        rules,
        contains(
          "auth != null && root.child('users')"
          ".child(auth.uid).child('active')"
          ".val() === true",
        ),
      );
    });

    test('restricts Product writes by role', () {
      for (final String role in <String>[
        'ADMIN',
        'MANAGER',
        'SUPERVISOR',
        'INVENTORY_USER',
      ]) {
        expect(
          rules,
          contains("'$role'"),
        );
      }
    });

    test('requires Product business fields', () {
      for (final String field in <String>[
        'id',
        'sku',
        'productName',
        'cost',
        'retailPrice',
        'vat',
        'active',
        'inventoryMode',
        'costingMethod',
        'createdAt',
        'updatedAt',
        'serverVersion',
      ]) {
        expect(
          rules,
          contains("'$field'"),
        );
      }
    });

    test('matches Product ID to Firebase key', () {
      expect(
        rules,
        contains(
          "newData.child('id').val() "
          "=== \$productId",
        ),
      );
    });

    test('allows supported Inventory Modes', () {
      for (final String value in <String>[
        'DIRECT',
        'RECIPE',
        'NONE',
      ]) {
        expect(
          rules,
          contains("'$value'"),
        );
      }
    });

    test('allows supported Costing Methods', () {
      for (final String value in <String>[
        'MANUAL',
        'INGREDIENT',
        'HYBRID',
      ]) {
        expect(
          rules,
          contains("'$value'"),
        );
      }
    });

    test('requires Recipe ID for Recipe mode', () {
      expect(
        rules,
        contains(
          "newData.child('inventoryMode')"
          ".val() === 'RECIPE'",
        ),
      );

      expect(
        rules,
        contains(
          "newData.child('recipeId')"
          ".val().length > 0",
        ),
      );
    });

    test('restricts Ingredient costing to Recipe mode', () {
      expect(
        rules,
        contains(
          "newData.child('costingMethod')"
          ".val() !== 'INGREDIENT'",
        ),
      );
    });

    test('requires non-negative financial values', () {
      for (final String field in <String>[
        'cost',
        'retailPrice',
        'vat',
        'serverVersion',
      ]) {
        expect(
          rules,
          contains(
            "newData.child('$field').val() >= 0",
          ),
        );
      }
    });

    test('requires deleted Products to be inactive', () {
      expect(
        rules,
        contains(
          "newData.child('deletedAt')",
        ),
      );

      expect(
        rules,
        contains(
          "newData.child('active')"
          ".val() === false",
        ),
      );
    });

    test('does not require local sync status', () {
      final dynamic root = decoded['rules'];
      final dynamic products = root['products'];
      final dynamic product = products[r'$productId'];

      final String validation = product['.validate'] as String;

      expect(
        validation.contains(
          "hasChildren(['syncStatus",
        ),
        isFalse,
      );
    });
  });
}
