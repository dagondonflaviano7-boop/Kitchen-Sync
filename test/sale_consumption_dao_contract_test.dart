import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final File daoFile = File(
      'lib/data/local/daos/'
      'sale_consumption_dao.dart',
    );

    if (!daoFile.existsSync()) {
      throw StateError(
        'Sale Consumption DAO does not exist at '
        '${daoFile.path}.',
      );
    }

    source = daoFile.readAsStringSync();
  });

  group('Sale Consumption DAO contract', () {
    group('DAO definition', () {
      test('imports the Sale Consumption domain', () {
        expect(
          source,
          contains(
            "import 'package:kitchen_sync/domain/models/"
            "sale_consumption.dart';",
          ),
        );
      });

      test('imports the Product model', () {
        expect(
          source,
          contains(
            "import 'package:kitchen_sync/domain/models/"
            "product.dart';",
          ),
        );
      });

      test('imports SQLite support', () {
        expect(
          source,
          contains(
            "import 'package:sqflite/sqflite.dart';",
          ),
        );
      });

      test('defines SaleConsumptionDao', () {
        expect(
          source,
          contains(
            'class SaleConsumptionDao',
          ),
        );
      });

      test('defines executePlan', () {
        expect(
          source,
          contains(
            'Future<void> executePlan(',
          ),
        );
      });

      test('accepts DatabaseExecutor', () {
        expect(
          source,
          contains(
            'DatabaseExecutor database',
          ),
        );
      });

      test('accepts SaleConsumptionPlan', () {
        expect(
          source,
          contains(
            'SaleConsumptionPlan plan',
          ),
        );
      });
    });

    group('Plan validation and routing', () {
      test('validates the plan', () {
        expect(
          source,
          contains(
            'plan.validate();',
          ),
        );
      });

      test('handles DIRECT mode', () {
        expect(
          containsAny(
            source,
            const <String>[
              'ProductInventoryMode.direct',
              'plan.usesDirectInventory',
            ],
          ),
          isTrue,
        );
      });

      test('handles RECIPE mode', () {
        expect(
          containsAny(
            source,
            const <String>[
              'ProductInventoryMode.recipe',
              'plan.usesRecipeInventory',
            ],
          ),
          isTrue,
        );
      });

      test('handles NONE mode', () {
        expect(
          containsAny(
            source,
            const <String>[
              'ProductInventoryMode.none',
              'plan.ignoresInventory',
            ],
          ),
          isTrue,
        );
      });

      test('uses planned quantity delta', () {
        expect(
          source,
          contains(
            'movement.quantityDelta',
          ),
        );
      });

      test('does not calculate Recipe requirements', () {
        expect(
          compact(source),
          isNot(
            contains(
              compact(
                'quantityRequired / yieldQuantity',
              ),
            ),
          ),
        );
      });
    });

    group('Product inventory persistence', () {
      test('queries Product inventory', () {
        expect(
          source,
          contains(
            "'inventory'",
          ),
        );

        expect(
          source,
          contains(
            'store_id = ? AND product_id = ?',
          ),
        );
      });

      test('reads Product quantity', () {
        expect(
          source,
          contains(
            "'quantity'",
          ),
        );
      });

      test('updates Product inventory', () {
        expect(
          hasDatabaseOperation(
            source,
            operation: 'update',
            table: 'inventory',
          ),
          isTrue,
        );
      });

      test('writes Product quantity and timestamp', () {
        expect(
          source,
          contains(
            "'quantity': afterQuantity",
          ),
        );

        expect(
          source,
          contains(
            "'updated_at':",
          ),
        );
      });

      test('detects missing Product inventory', () {
        expect(
          source,
          contains(
            'Product Inventory record was not found.',
          ),
        );
      });
    });

    group('Ingredient inventory persistence', () {
      test('queries Ingredient inventory', () {
        expect(
          source,
          contains(
            "'ingredient_inventory'",
          ),
        );

        expect(
          source,
          contains(
            'store_id = ? AND ingredient_id = ?',
          ),
        );
      });

      test('updates Ingredient inventory', () {
        expect(
          hasDatabaseOperation(
            source,
            operation: 'update',
            table: 'ingredient_inventory',
          ),
          isTrue,
        );
      });

      test('writes Ingredient quantity and timestamp', () {
        expect(
          source,
          contains(
            "'quantity': afterQuantity",
          ),
        );

        expect(
          source,
          contains(
            "'updated_at':",
          ),
        );
      });

      test('detects missing Ingredient inventory', () {
        expect(
          source,
          contains(
            'Ingredient Inventory record was not found.',
          ),
        );
      });

      test('iterates through planned movements', () {
        expect(
          compact(source),
          contains(
            compact(
              'for (final PlannedInventoryMovement '
              'movement in plan.movements)',
            ),
          ),
        );
      });
    });

    group('Balance calculation', () {
      test('calculates after quantity using delta', () {
        expect(
          compact(source),
          contains(
            compact(
              'beforeQuantity + '
              'movement.quantityDelta',
            ),
          ),
        );
      });

      test('does not update average cost', () {
        expect(
          hasMapAssignment(
            source,
            'average_cost',
          ),
          isFalse,
        );
      });
    });

    group('Movement table routing', () {
      test('routes Product movements', () {
        expect(
          compact(source),
          contains(
            compact(
              "table: 'inventory_movements'",
            ),
          ),
        );
      });

      test('routes Ingredient movements', () {
        expect(
          compact(source),
          contains(
            compact(
              "table: 'ingredient_movements'",
            ),
          ),
        );
      });

      test('inserts through the selected movement table', () {
        expect(
          compact(source),
          contains(
            compact(
              'database.insert('
              'table,',
            ),
          ),
        );
      });
    });

    group('Movement audit values', () {
      test('stores movement ID and item ID', () {
        expect(
          source,
          contains(
            "'id': movementId",
          ),
        );

        expect(
          source,
          contains(
            "'item_id': movement.itemId",
          ),
        );
      });

      test('stores idempotency key', () {
        expect(
          compact(source),
          contains(
            compact(
              "'idempotency_key': "
              "movement.idempotencyKey",
            ),
          ),
        );
      });

      test('stores Sale ID', () {
        expect(
          compact(source),
          contains(
            compact(
              "'source_sale_id': "
              "movement.sourceSaleId",
            ),
          ),
        );
      });

      test('stores Sale Item ID', () {
        expect(
          compact(source),
          contains(
            compact(
              "'source_sale_item_id': "
              "movement.sourceSaleItemId",
            ),
          ),
        );
      });

      test('stores reversal reference', () {
        expect(
          compact(source),
          contains(
            compact(
              "'reversal_of_movement_id': "
              "movement.reversalOfMovementId",
            ),
          ),
        );
      });

      test('stores unit cost snapshot', () {
        expect(
          compact(source),
          contains(
            compact(
              "'unit_cost_snapshot': "
              "movement.unitCostSnapshot",
            ),
          ),
        );
      });

      test('stores quantity delta', () {
        expect(
          compact(source),
          contains(
            compact(
              "'quantity': "
              "movement.quantityDelta",
            ),
          ),
        );
      });

      test('stores before and after quantities', () {
        expect(
          compact(source),
          contains(
            compact(
              "'before_quantity': beforeQuantity",
            ),
          ),
        );

        expect(
          compact(source),
          contains(
            compact(
              "'after_quantity': afterQuantity",
            ),
          ),
        );
      });

      test('stores operation using domain converter', () {
        expect(
          source,
          contains(
            'consumptionOperationToStorage(',
          ),
        );

        expect(
          source,
          contains(
            'movement.operation',
          ),
        );
      });

      test('stores reference ID', () {
        expect(
          compact(source),
          contains(
            compact(
              "'reference_id': "
              "movement.sourceSaleId",
            ),
          ),
        );
      });

      test('stores user and device fields', () {
        expect(
          compact(source),
          contains(
            compact(
              "'user_id': movement.performedBy",
            ),
          ),
        );

        expect(
          compact(source),
          contains(
            compact(
              "'device_id': movement.deviceId",
            ),
          ),
        );
      });

      test('stores UTC occurrence timestamp', () {
        expect(
          compact(source),
          contains(
            compact(
              'movement.occurredAt'
              '.toUtc()'
              '.toIso8601String()',
            ),
          ),
        );
      });

      test('stores remarks', () {
        expect(
          source,
          contains(
            "'remarks':",
          ),
        );
      });
    });

    group('Idempotency', () {
      test('checks idempotency keys', () {
        expect(
          source,
          contains(
            'idempotency_key = ?',
          ),
        );

        expect(
          source,
          contains(
            'movement.idempotencyKey',
          ),
        );
      });

      test('queries both movement tables', () {
        expect(
          source,
          contains(
            "'inventory_movements'",
          ),
        );

        expect(
          source,
          contains(
            "'ingredient_movements'",
          ),
        );
      });

      test('has already-applied behavior', () {
        expect(
          containsAny(
            source,
            const <String>[
              'alreadyApplied',
              'alreadyExists',
              'isAlreadyApplied',
              'movementExists',
              'rows.isNotEmpty',
            ],
          ),
          isTrue,
        );
      });

      test('does not silently swallow all errors', () {
        expect(
          compact(source),
          isNot(
            contains(
              'catch(_){}',
            ),
          ),
        );
      });
    });

    group('Restoration validation', () {
      test('recognizes restoration movements', () {
        expect(
          containsAny(
            source,
            const <String>[
              'movement.isRestoration',
              'ConsumptionOperation.restore',
            ],
          ),
          isTrue,
        );
      });

      test('uses original movement reference', () {
        expect(
          source,
          contains(
            'movement.reversalOfMovementId',
          ),
        );
      });

      test('looks up the original movement', () {
        expect(
          source,
          contains(
            'id = ?',
          ),
        );
      });

      test('rejects missing original movement', () {
        expect(
          source,
          contains(
            'Original movement was not found.',
          ),
        );
      });

      test('validates original item and Store', () {
        expect(
          source,
          contains(
            "originalMovement['item_id']",
          ),
        );

        expect(
          source,
          contains(
            "originalMovement['store_id']",
          ),
        );
      });

      test('checks existing reversal', () {
        expect(
          source,
          contains(
            'reversal_of_movement_id = ?',
          ),
        );
      });

      test('rejects duplicate restoration', () {
        expect(
          source,
          contains(
            'Movement has already been restored.',
          ),
        );
      });
    });

    group('Transaction ownership', () {
      test('does not open AppDatabase', () {
        expect(
          source,
          isNot(
            contains(
              'AppDatabase.instance.database',
            ),
          ),
        );
      });

      test('does not start an internal transaction', () {
        expect(
          source,
          isNot(
            contains(
              'database.transaction(',
            ),
          ),
        );
      });

      test('does not import the database singleton', () {
        expect(
          source,
          isNot(
            contains(
              'data/local/database.dart',
            ),
          ),
        );
      });
    });

    group('Layer boundaries', () {
      test('does not import Recipe repository', () {
        expect(
          source,
          isNot(
            contains(
              'recipe_repository.dart',
            ),
          ),
        );
      });

      test('does not import Unit repository', () {
        expect(
          source,
          isNot(
            contains(
              'unit_of_measure_repository.dart',
            ),
          ),
        );
      });

      test('does not perform unit conversion', () {
        expect(
          source,
          isNot(
            contains(
              'convertQuantity(',
            ),
          ),
        );

        expect(
          source,
          isNot(
            contains(
              'conversionFactor',
            ),
          ),
        );
      });

      test('does not write Sales tables', () {
        expect(
          hasDatabaseWrite(
            source,
            'sales',
          ),
          isFalse,
        );

        expect(
          hasDatabaseWrite(
            source,
            'sale_items',
          ),
          isFalse,
        );
      });
    });
  });
}

bool containsAny(
  String source,
  List<String> candidates,
) {
  return candidates.any(source.contains);
}

String compact(
  String value,
) {
  return value.replaceAll(
    RegExp(r'\s+'),
    '',
  );
}

bool hasDatabaseOperation(
  String source, {
  required String operation,
  required String table,
}) {
  final String normalized = compact(source);

  return normalized.contains(
    "database.$operation('$table',",
  );
}

bool hasMapAssignment(
  String source,
  String key,
) {
  final String normalized = compact(source);

  return normalized.contains(
    "'$key':",
  );
}

bool hasDatabaseWrite(
  String source,
  String table,
) {
  for (final String operation in <String>[
    'insert',
    'update',
    'delete',
  ]) {
    if (hasDatabaseOperation(
      source,
      operation: operation,
      table: table,
    )) {
      return true;
    }
  }

  return false;
}
