import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> ingredientRules;
  late String validation;

  setUpAll(() {
    final Map<String, dynamic> document = jsonDecode(
      File(
        'firebase/database.rules.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;

    final Map<String, dynamic> rules =
        document['rules'] as Map<String, dynamic>;

    ingredientRules = rules['ingredients'] as Map<String, dynamic>;

    final Map<String, dynamic> itemRules =
        ingredientRules[r'$ingredientId'] as Map<String, dynamic>;

    validation = itemRules['.validate'] as String;
  });

  test('allows collection reads for active users', () {
    expect(
      ingredientRules,
      contains('.read'),
    );

    expect(
      ingredientRules['.read'],
      contains(
        "child('active').val() === true",
      ),
    );
  });

  test('protects Ingredient writes by role', () {
    final Map<String, dynamic> itemRules =
        ingredientRules[r'$ingredientId'] as Map<String, dynamic>;

    final String writeRule = itemRules['.write'] as String;

    expect(writeRule, contains("'ADMIN'"));
    expect(writeRule, contains("'MANAGER'"));
    expect(writeRule, contains("'SUPERVISOR'"));
    expect(
      writeRule,
      contains("'INVENTORY_USER'"),
    );
  });

  test('requires core Ingredient fields', () {
    for (final String field in <String>[
      'id',
      'ingredientSku',
      'ingredientName',
      'category',
      'unitOfMeasure',
      'conversionFactor',
      'cost',
      'minimumStock',
      'active',
      'createdAt',
      'updatedAt',
      'serverVersion',
    ]) {
      expect(
        validation,
        contains("'$field'"),
      );
    }
  });

  test('requires positive conversion factor', () {
    expect(
      validation,
      contains(
        "child('conversionFactor').val() > 0",
      ),
    );
  });

  test('requires non-negative cost', () {
    expect(
      validation,
      contains(
        "child('cost').val() >= 0",
      ),
    );
  });

  test('requires non-negative minimum stock', () {
    expect(
      validation,
      contains(
        "child('minimumStock').val() >= 0",
      ),
    );
  });

  test('prevents Par Level below Reorder Level', () {
    expect(
      validation,
      contains(
        "child('maximumStock').val() >= "
        "newData.child('minimumStock').val()",
      ),
    );
  });

  test('requires deletion tombstone to be inactive', () {
    expect(
      validation,
      contains(
        "child('active').val() === false",
      ),
    );
  });

  test('allows nullable optional fields', () {
    for (final String field in <String>[
      'purchaseUnit',
      'supplierId',
      'supplierName',
      'notes',
      'imagePath',
      'deletedAt',
    ]) {
      expect(
        validation,
        contains(
          "child('$field')",
        ),
      );

      expect(
        validation,
        contains(
          "child('$field').val() == null",
        ),
      );
    }
  });

  test(
    'requires Ingredient ID to match the Firebase node key',
    () {
      expect(
        validation,
        contains(
          "newData.child('id').val() === "
          r"$ingredientId",
        ),
      );
    },
  );
}
