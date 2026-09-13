import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File repositoryFile = File(
      'lib/data/repositories/sale_posting_repository.dart',
    );

    expect(
      repositoryFile.existsSync(),
      isTrue,
      reason: 'Sale Posting repository must exist.',
    );

    source = repositoryFile.readAsStringSync();
  });

  group('Sale Posting repository contract', () {
    test('defines Sale Posting repository', () {
      expect(
        source,
        contains(
          'class SalePostingRepository',
        ),
      );

      expect(
        source,
        contains(
          'const SalePostingRepository({',
        ),
      );
    });

    test('declares required dependencies', () {
      for (final String dependency in <String>[
        'ProductDao productDao',
        'RecipeDao recipeDao',
        'SalePostingDao salePostingDao',
        'SaleConsumptionDao saleConsumptionDao',
        'SaleConsumptionPlanner saleConsumptionPlanner',
      ]) {
        expect(
          source,
          contains(dependency),
          reason: 'Repository must declare $dependency.',
        );
      }
    });

    test('provides default dependency implementations', () {
      for (final String defaultValue in <String>[
        'this.productDao = const ProductDao()',
        'this.recipeDao = const RecipeDao()',
        'this.salePostingDao = const SalePostingDao()',
        'this.saleConsumptionDao = const SaleConsumptionDao()',
        'this.saleConsumptionPlanner = const SaleConsumptionPlanner()',
      ]) {
        expect(
          source,
          contains(defaultValue),
          reason: 'Repository must provide $defaultValue.',
        );
      }
    });

    test('provides posting entry point', () {
      expect(
        source,
        contains(
          'Future<void> postSale(',
        ),
      );

      expect(
        source,
        contains(
          'SalePostingRequest request',
        ),
      );

      expect(
        source,
        contains(
          'request.validate()',
        ),
      );
    });

    test('opens one atomic database transaction', () {
      expect(
        source,
        contains(
          'final Database database = await AppDatabase.instance.database',
        ),
      );

      expect(
        source,
        contains(
          'return database.transaction(',
        ),
      );

      expect(
        source,
        contains(
          '(Transaction transaction) async',
        ),
      );
    });

    test('checks duplicate sale inside transaction', () {
      expect(
        source,
        contains(
          'salePostingDao.saleExists(',
        ),
      );

      expect(
        source,
        contains(
          'transaction,',
        ),
      );

      expect(
        source,
        contains(
          'Sale has already been posted.',
        ),
      );
    });

    test('loads every active Product', () {
      expect(
        source,
        contains(
          'for (final SalePostingItem item in request.items)',
        ),
      );

      expect(
        source,
        contains(
          'productDao.findById(',
        ),
      );

      expect(
        source,
        contains(
          'The Sale Product was not found or is inactive.',
        ),
      );
    });

    test('loads linked Recipe for Recipe inventory mode', () {
      expect(
        source,
        contains(
          'ProductInventoryMode.recipe',
        ),
      );

      expect(
        source,
        contains(
          'recipeDao.getRecipeById(',
        ),
      );

      expect(
        source,
        contains(
          'product.recipeId',
        ),
      );
    });

    test('creates a consumption request and plan per item', () {
      expect(
        source,
        contains(
          'item.toConsumptionRequest(',
        ),
      );

      expect(
        source,
        contains(
          'saleConsumptionPlanner.createPlan(',
        ),
      );

      expect(
        source,
        contains(
          'SaleConsumptionPlan',
        ),
      );
    });

    test('persists sale posting in the transaction', () {
      expect(
        source,
        contains(
          'salePostingDao.insertPosting(',
        ),
      );

      expect(
        source,
        contains(
          'transaction,',
        ),
      );
    });

    test('executes all consumption plans in same transaction', () {
      expect(
        source,
        contains(
          'for (final SaleConsumptionPlan plan in plans)',
        ),
      );

      expect(
        source,
        contains(
          'saleConsumptionDao.executePlan(',
        ),
      );

      expect(
        source,
        contains(
          'transaction,',
        ),
      );
    });

    test('does not open nested transactions', () {
      final int transactionCalls = RegExp(
        r'\.transaction\(',
      ).allMatches(source).length;

      expect(
        transactionCalls,
        1,
        reason: 'Repository must open exactly one transaction.',
      );
    });

    test('normalizes identifiers through domain mappings', () {
      expect(
        source,
        contains(
          'saleId: request.saleId',
        ),
      );

      expect(
        source,
        contains(
          'storeId: request.storeId',
        ),
      );

      expect(
        source,
        contains(
          'performedBy: request.cashierId',
        ),
      );

      expect(
        source,
        contains(
          'deviceId: request.deviceId',
        ),
      );
    });
  });
}
