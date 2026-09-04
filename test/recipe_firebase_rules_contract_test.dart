import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> recipeRules;
  late Map<String, dynamic> itemRules;
  late Map<String, dynamic> ingredientRules;
  late String validation;
  late String ingredientValidation;

  setUpAll(() {
    final Map<String, dynamic> document = jsonDecode(
      File(
        'firebase/database.rules.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;

    final Map<String, dynamic> rules =
        document['rules'] as Map<String, dynamic>;

    recipeRules = rules['recipes'] as Map<String, dynamic>;

    itemRules = recipeRules[r'$recipeId'] as Map<String, dynamic>;

    validation = itemRules['.validate'] as String;

    final Map<String, dynamic> ingredients =
        itemRules['ingredients'] as Map<String, dynamic>;

    ingredientRules =
        ingredients[r'$recipeIngredientId'] as Map<String, dynamic>;

    ingredientValidation = ingredientRules['.validate'] as String;
  });

  test('allows Recipe reads for active users', () {
    expect(recipeRules, contains('.read'));

    expect(
      recipeRules['.read'],
      contains(
        "child('active').val() === true",
      ),
    );
  });

  test('protects Recipe writes by role', () {
    final String writeRule = itemRules['.write'] as String;

    expect(writeRule, contains("'ADMIN'"));
    expect(writeRule, contains("'MANAGER'"));
    expect(writeRule, contains("'SUPERVISOR'"));

    expect(
      writeRule,
      contains("'INVENTORY_USER'"),
    );
  });

  test('requires core Recipe fields', () {
    for (final String field in <String>[
      'id',
      'recipeCode',
      'recipeName',
      'category',
      'yieldQuantity',
      'yieldUnitCode',
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

  test('requires Recipe ID to match node key', () {
    expect(
      validation,
      contains(
        "newData.child('id').val() === "
        r"$recipeId",
      ),
    );
  });

  test('requires positive Recipe yield', () {
    expect(
      validation,
      contains(
        "child('yieldQuantity').val() > 0",
      ),
    );
  });

  test('restricts Recipe categories', () {
    for (final String category in <String>[
      'mainDish',
      'sideDish',
      'beverage',
      'dessert',
      'sauce',
      'ingredientPrep',
    ]) {
      expect(
        validation,
        contains("'$category'"),
      );
    }
  });

  test('requires non-negative server version', () {
    expect(
      validation,
      contains(
        "child('serverVersion').val() >= 0",
      ),
    );
  });

  test('requires tombstones to be inactive', () {
    expect(
      validation,
      contains(
        "child('active').val() === false",
      ),
    );
  });

  test('validates nested Recipe Ingredients', () {
    for (final String field in <String>[
      'id',
      'recipeId',
      'ingredientId',
      'ingredientSku',
      'ingredientName',
      'usageUnitCode',
      'quantityRequired',
      'costPerUsageUnit',
    ]) {
      expect(
        ingredientValidation,
        contains("'$field'"),
      );
    }
  });

  test('requires Ingredient line ID to match key', () {
    expect(
      ingredientValidation,
      contains(
        "newData.child('id').val() === "
        r"$recipeIngredientId",
      ),
    );
  });

  test('requires Ingredient line Recipe ID', () {
    expect(
      ingredientValidation,
      contains(
        "newData.child('recipeId').val() === "
        r"$recipeId",
      ),
    );
  });

  test('requires positive Ingredient quantity', () {
    expect(
      ingredientValidation,
      contains(
        "child('quantityRequired').val() > 0",
      ),
    );
  });

  test('allows zero Ingredient cost', () {
    expect(
      ingredientValidation,
      contains(
        "child('costPerUsageUnit').val() >= 0",
      ),
    );
  });
}
