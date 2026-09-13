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

  group('Sale Posting repository costing persistence contract', () {
    test('imports authoritative costing domain', () {
      expect(
        source,
        contains(
          "import 'package:kitchen_sync/domain/models/"
          "sale_posting_costing.dart'",
        ),
      );
    });

    test('declares authoritative costing planner dependency', () {
      expect(
        source,
        contains(
          'final SalePostingCostingPlanner '
          'salePostingCostingPlanner',
        ),
      );

      expect(
        source,
        contains(
          'this.salePostingCostingPlanner = '
          'const SalePostingCostingPlanner()',
        ),
      );
    });

    test('creates costing snapshot from request and plans', () {
      expect(
        source,
        contains(
          'final SalePostingCostingSnapshot costing',
        ),
      );

      expect(
        source,
        contains(
          'salePostingCostingPlanner.createSnapshot(',
        ),
      );

      expect(
        source,
        contains(
          'request: request',
        ),
      );

      expect(
        source,
        contains(
          'plans: plans',
        ),
      );
    });

    test('validates costing snapshot before persistence', () {
      expect(
        source,
        contains(
          'costing.validate()',
        ),
      );
    });

    test('passes costing snapshot to Sale Posting DAO', () {
      expect(
        source,
        matches(
          RegExp(
            r'await\s+salePostingDao\.insertPosting\s*\('
            r'[\s\S]*?transaction\s*,'
            r'[\s\S]*?request\s*,'
            r'[\s\S]*?costing\s*,?'
            r'[\s\S]*?\)\s*;',
          ),
        ),
      );
    });

    test('builds costing after all consumption plans', () {
      final int planningLoopIndex = source.indexOf(
        'for (final SalePostingItem item in request.items)',
      );

      final int costingIndex = source.indexOf(
        'salePostingCostingPlanner.createSnapshot(',
      );

      final int persistenceIndex = source.indexOf(
        'salePostingDao.insertPosting(',
      );

      expect(
        planningLoopIndex,
        greaterThanOrEqualTo(0),
      );

      expect(
        costingIndex,
        greaterThan(planningLoopIndex),
        reason: 'Costing must be created after consumption planning.',
      );

      expect(
        persistenceIndex,
        greaterThan(costingIndex),
        reason: 'Costing must be created before Sale persistence.',
      );
    });

    test('keeps costing inside the existing transaction', () {
      final int transactionIndex = source.indexOf(
        'return database.transaction(',
      );

      final int costingIndex = source.indexOf(
        'salePostingCostingPlanner.createSnapshot(',
      );

      expect(
        transactionIndex,
        greaterThanOrEqualTo(0),
      );

      expect(
        costingIndex,
        greaterThan(transactionIndex),
      );

      expect(
        RegExp(
          r'\.transaction\(',
        ).allMatches(source).length,
        1,
        reason: 'Repository must continue using exactly one transaction.',
      );
    });

    test('executes consumption after Sale costing persistence', () {
      final int persistenceIndex = source.indexOf(
        'salePostingDao.insertPosting(',
      );

      final int executionIndex = source.indexOf(
        'for (final SaleConsumptionPlan plan in plans)',
      );

      expect(
        persistenceIndex,
        greaterThanOrEqualTo(0),
      );

      expect(
        executionIndex,
        greaterThan(persistenceIndex),
        reason: 'Inventory consumption must remain after Sale persistence.',
      );
    });

    test('does not recalculate costing in repository', () {
      expect(
        source,
        isNot(
          contains(
            'plan.expectedCost *',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'product.cost *',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'grossProfit =',
          ),
        ),
      );

      expect(
        source,
        isNot(
          contains(
            'grossMargin =',
          ),
        ),
      );
    });

    test('does not add another database transaction', () {
      expect(
        RegExp(
          r'\.transaction\(',
        ).allMatches(source).length,
        1,
      );
    });
  });
}
