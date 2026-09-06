import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:sqflite/sqflite.dart';

class SaleConsumptionDao {
  const SaleConsumptionDao();

  Future<void> executePlan(
    DatabaseExecutor database,
    SaleConsumptionPlan plan,
  ) async {
    plan.validate();

    switch (plan.inventoryMode) {
      case ProductInventoryMode.direct:
        await _executeProductMovement(
          database,
          plan.movements.single,
        );

      case ProductInventoryMode.recipe:
        for (final PlannedInventoryMovement movement in plan.movements) {
          await _executeIngredientMovement(
            database,
            movement,
          );
        }

      case ProductInventoryMode.none:
        return;
    }
  }

  Future<void> _executeProductMovement(
    DatabaseExecutor database,
    PlannedInventoryMovement movement,
  ) async {
    final bool alreadyApplied = await _movementExists(
      database,
      table: 'inventory_movements',
      movement: movement,
    );

    if (alreadyApplied) {
      return;
    }

    if (movement.isRestoration) {
      await _validateRestoration(
        database,
        table: 'inventory_movements',
        movement: movement,
      );
    }

    final double beforeQuantity = await _readProductQuantity(
      database,
      movement,
    );

    final double afterQuantity = beforeQuantity + movement.quantityDelta;

    final int updated = await database.update(
      'inventory',
      <String, Object?>{
        'quantity': afterQuantity,
        'updated_at': movement.occurredAt.toUtc().toIso8601String(),
      },
      where: 'store_id = ? AND product_id = ?',
      whereArgs: <Object?>[
        movement.storeId.trim(),
        movement.itemId.trim(),
      ],
    );

    if (updated != 1) {
      throw StateError(
        'Product Inventory update failed.',
      );
    }

    await _insertMovement(
      database,
      table: 'inventory_movements',
      movement: movement,
      beforeQuantity: beforeQuantity,
      afterQuantity: afterQuantity,
    );
  }

  Future<void> _executeIngredientMovement(
    DatabaseExecutor database,
    PlannedInventoryMovement movement,
  ) async {
    final bool alreadyApplied = await _movementExists(
      database,
      table: 'ingredient_movements',
      movement: movement,
    );

    if (alreadyApplied) {
      return;
    }

    if (movement.isRestoration) {
      await _validateRestoration(
        database,
        table: 'ingredient_movements',
        movement: movement,
      );
    }

    final double beforeQuantity = await _readIngredientQuantity(
      database,
      movement,
    );

    final double afterQuantity = beforeQuantity + movement.quantityDelta;

    final int updated = await database.update(
      'ingredient_inventory',
      <String, Object?>{
        'quantity': afterQuantity,
        'updated_at': movement.occurredAt.toUtc().toIso8601String(),
      },
      where: 'store_id = ? AND ingredient_id = ?',
      whereArgs: <Object?>[
        movement.storeId.trim(),
        movement.itemId.trim(),
      ],
    );

    if (updated != 1) {
      throw StateError(
        'Ingredient Inventory update failed.',
      );
    }

    await _insertMovement(
      database,
      table: 'ingredient_movements',
      movement: movement,
      beforeQuantity: beforeQuantity,
      afterQuantity: afterQuantity,
    );
  }

  Future<double> _readProductQuantity(
    DatabaseExecutor database,
    PlannedInventoryMovement movement,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'inventory',
      columns: const <String>[
        'quantity',
      ],
      where: 'store_id = ? AND product_id = ?',
      whereArgs: <Object?>[
        movement.storeId.trim(),
        movement.itemId.trim(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError(
        'Inventory balance was not found.',
      );
    }

    return _requiredQuantity(
      rows.single['quantity'],
      'Product Inventory quantity',
    );
  }

  Future<double> _readIngredientQuantity(
    DatabaseExecutor database,
    PlannedInventoryMovement movement,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'ingredient_inventory',
      columns: const <String>[
        'quantity',
      ],
      where: 'store_id = ? AND ingredient_id = ?',
      whereArgs: <Object?>[
        movement.storeId.trim(),
        movement.itemId.trim(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError(
        'Ingredient Inventory balance was not found.',
      );
    }

    return _requiredQuantity(
      rows.single['quantity'],
      'Ingredient Inventory quantity',
    );
  }

  Future<void> _insertMovement(
    DatabaseExecutor database, {
    required String table,
    required PlannedInventoryMovement movement,
    required double beforeQuantity,
    required double afterQuantity,
  }) async {
    final String movementId = _movementId(
      movement,
    );

    await database.insert(
      table,
      <String, Object?>{
        'id': movementId,
        'store_id': movement.storeId.trim(),
        'item_id': movement.itemId.trim(),
        'quantity': movement.quantityDelta,
        'before_quantity': beforeQuantity,
        'after_quantity': afterQuantity,
        'movement_type': consumptionOperationToStorage(
          movement.operation,
        ),
        'reference_id': movement.sourceSaleId,
        'user_id': movement.performedBy,
        'device_id': movement.deviceId,
        'created_at': movement.occurredAt.toUtc().toIso8601String(),
        'remarks': _movementRemarks(
          movement,
        ),
        'idempotency_key': movement.idempotencyKey,
        'source_sale_id': movement.sourceSaleId,
        'source_sale_item_id': movement.sourceSaleItemId,
        'reversal_of_movement_id': movement.reversalOfMovementId,
        'unit_cost_snapshot': movement.unitCostSnapshot,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<bool> hasProcessedMovement(
    DatabaseExecutor database,
    PlannedInventoryMovement movement,
  ) async {
    movement.validate();

    final String table = switch (movement.itemType) {
      ConsumptionItemType.product => 'inventory_movements',
      ConsumptionItemType.ingredient => 'ingredient_movements',
    };

    return _movementExists(
      database,
      table: table,
      movement: movement,
    );
  }

  Future<bool> _movementExists(
    DatabaseExecutor database, {
    required String table,
    required PlannedInventoryMovement movement,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      table,
      columns: const <String>[
        'id',
      ],
      where: 'idempotency_key = ?',
      whereArgs: <Object?>[
        movement.idempotencyKey.trim(),
      ],
      limit: 1,
    );

    final bool movementExists = rows.isNotEmpty;
    return movementExists;
  }

  String _movementId(
    PlannedInventoryMovement movement,
  ) {
    return movement.idempotencyKey.trim();
  }

  String _movementRemarks(
    PlannedInventoryMovement movement,
  ) {
    final String operation = consumptionOperationToStorage(
      movement.operation,
    );

    final String itemType = consumptionItemTypeToStorage(
      movement.itemType,
    );

    return '$operation $itemType movement '
        'for Sale ${movement.sourceSaleId.trim()} '
        'and Sale Item '
        '${movement.sourceSaleItemId.trim()}.';
  }

  Future<void> _validateRestoration(
    DatabaseExecutor database, {
    required String table,
    required PlannedInventoryMovement movement,
  }) async {
    final String reversalOfMovementId =
        movement.reversalOfMovementId?.trim() ?? '';

    final List<Map<String, Object?>> originalRows = await database.query(
      table,
      columns: const <String>[
        'id',
        'item_id',
        'store_id',
      ],
      where: 'id = ?',
      whereArgs: <Object?>[
        reversalOfMovementId,
      ],
      limit: 1,
    );

    if (originalRows.isEmpty) {
      throw StateError(
        'Original movement was not found.',
      );
    }

    final Map<String, Object?> originalMovement = originalRows.single;

    if (originalMovement['item_id']?.toString().trim() !=
        movement.itemId.trim()) {
      throw StateError(
        'Original movement Item does not match.',
      );
    }

    if (originalMovement['store_id']?.toString().trim() !=
        movement.storeId.trim()) {
      throw StateError(
        'Original movement Store does not match.',
      );
    }

    final List<Map<String, Object?>> reversalRows = await database.query(
      table,
      columns: const <String>[
        'id',
      ],
      where: 'reversal_of_movement_id = ?',
      whereArgs: <Object?>[
        reversalOfMovementId,
      ],
      limit: 1,
    );

    if (reversalRows.isNotEmpty) {
      throw StateError(
        'Original movement was already restored.',
      );
    }
  }

  double _requiredQuantity(
    Object? value,
    String fieldName,
  ) {
    final double? quantity = value is num
        ? value.toDouble()
        : double.tryParse(
            value?.toString() ?? '',
          );

    if (quantity == null || !quantity.isFinite) {
      throw FormatException(
        '$fieldName must be a valid number.',
      );
    }

    return quantity;
  }
}
