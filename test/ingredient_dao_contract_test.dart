import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/data/local/daos/ingredient_dao.dart',
    ).readAsStringSync();
  });

  group('Ingredient DAO core operations', () {
    test('uses the Ingredients table', () {
      expect(
        source,
        contains("'ingredients'"),
      );
    });

    test('supports local upsert', () {
      expect(
        source,
        contains('Future<void> upsert('),
      );
      expect(
        source,
        contains('ingredient.toSqlite()'),
      );
      expect(
        source,
        contains(
          'ConflictAlgorithm.replace',
        ),
      );
    });

    test('supports standard and sync lookups', () {
      expect(
        source,
        contains('Future<Ingredient?> findById('),
      );
      expect(
        source,
        contains(
          'Future<Ingredient?> '
          'findByIdIncludingDeleted(',
        ),
      );
      expect(
        source,
        contains('Future<Ingredient?> findBySku('),
      );
    });

    test('standard ID lookup excludes tombstones', () {
      expect(
        source,
        contains(
          "'id = ? AND deleted_at IS NULL'",
        ),
      );
    });

    test('SKU lookup normalizes input', () {
      expect(
        source,
        contains(
          'ingredientSku.trim().toUpperCase()',
        ),
      );
    });

    test('supports normal and including-deleted lists', () {
      expect(
        source,
        contains(
          'Future<List<Ingredient>> findAll(',
        ),
      );
      expect(
        source,
        contains(
          'Future<List<Ingredient>> '
          'findAllIncludingDeleted(',
        ),
      );
    });
  });

  group('Ingredient DAO search', () {
    test('searches required Ingredient fields', () {
      expect(
        source,
        contains('ingredient_sku LIKE ?'),
      );
      expect(
        source,
        contains('ingredient_name LIKE ?'),
      );
      expect(
        source,
        contains('category LIKE ?'),
      );
      expect(
        source,
        contains('supplier_name LIKE ?'),
      );
      expect(
        source,
        contains('unit_of_measure LIKE ?'),
      );
      expect(
        source,
        contains('purchase_unit LIKE ?'),
      );
    });

    test('supports Active filtering', () {
      expect(
        source,
        contains("conditions.add('active = ?')"),
      );
    });

    test('supports Category filtering', () {
      expect(
        source,
        contains(
          "conditions.add('category = ?')",
        ),
      );
      expect(
        source,
        contains(
          'ingredientCategoryToStorage(category)',
        ),
      );
    });

    test('supports Supplier filtering', () {
      expect(
        source,
        contains(
          "conditions.add('supplier_id = ?')",
        ),
      );
    });

    test('excludes tombstones from search', () {
      expect(
        source,
        contains("'deleted_at IS NULL'"),
      );
    });

    test('sorts by name and SKU', () {
      expect(
        source,
        contains(
          'ingredient_name COLLATE NOCASE',
        ),
      );
      expect(
        source,
        contains('ingredient_sku'),
      );
    });
  });

  group('Ingredient DAO duplicate protection', () {
    test('supports duplicate SKU detection', () {
      expect(
        source,
        contains('Future<bool> skuExists('),
      );
    });

    test('supports excluding the edited record', () {
      expect(
        source,
        contains('String? excludingId'),
      );
      expect(
        source,
        contains(r"'$where AND id != ?'"),
      );
    });

    test('ignores deleted records in duplicate checks', () {
      expect(
        source,
        contains(
          'ingredient_sku = ?\n'
          '      AND deleted_at IS NULL',
        ),
      );
    });
  });

  group('Ingredient DAO status and deletion', () {
    test('supports Active status changes', () {
      expect(
        source,
        contains('Future<void> setActive('),
      );
      expect(
        source,
        contains("'active': active ? 1 : 0"),
      );
    });

    test('status changes are marked pending', () {
      expect(
        source,
        contains("'sync_status': 'PENDING'"),
      );
    });

    test('status changes store Updated By', () {
      expect(
        source,
        contains("'updated_by': userId"),
      );
    });

    test('supports soft deletion', () {
      expect(
        source,
        contains('Future<void> softDelete('),
      );
      expect(
        source,
        contains("'deleted_at': timestamp"),
      );
      expect(
        source,
        contains("'active': 0"),
      );
    });

    test('soft delete preserves the row', () {
      expect(
        source,
        isNot(contains(
          "database.delete(\n"
          "      'ingredients'",
        )),
      );
    });

    test('deleted records cannot be updated normally', () {
      expect(
        source,
        contains(
          "'id = ? AND deleted_at IS NULL'",
        ),
      );
    });

    test('requires Updated By for status operations', () {
      expect(
        source,
        contains(
          "'Updated By is required.'",
        ),
      );
    });
  });

  group('Ingredient DAO reference checks', () {
    test('checks Recipe references', () {
      expect(
        source,
        contains("table: 'recipe_items'"),
      );
      expect(
        source,
        contains(
          "where: 'ingredient_id = ?'",
        ),
      );
    });

    test('checks Ingredient Inventory references', () {
      expect(
        source,
        contains(
          "table: 'ingredient_inventory'",
        ),
      );
    });

    test('checks Ingredient Movement references', () {
      expect(
        source,
        contains(
          "table: 'ingredient_movements'",
        ),
      );
      expect(
        source,
        contains("where: 'item_id = ?'"),
      );
    });

    test('checks Receiving references', () {
      expect(
        source,
        contains(
          "table: 'receiving_items'",
        ),
      );
    });

    test('checks Adjustment references', () {
      expect(
        source,
        contains(
          "table: 'adjustment_items'",
        ),
      );
    });

    test('generic item references require Ingredient type', () {
      expect(
        RegExp("'INGREDIENT'").allMatches(source).length,
        greaterThanOrEqualTo(2),
      );
    });
  });

  group('Ingredient DAO synchronization', () {
    test('finds Pending and Error records', () {
      expect(
        source,
        contains(
          "where: 'sync_status IN (?, ?)'",
        ),
      );
      expect(
        source,
        contains("'PENDING'"),
      );
      expect(
        source,
        contains("'ERROR'"),
      );
    });

    test('validates the pending query limit', () {
      expect(
        source,
        contains('if (limit < 1)'),
      );
    });

    test('supports Syncing status', () {
      expect(
        source,
        contains('Future<void> markSyncing('),
      );
      expect(
        source,
        contains('MasterSyncStatus.syncing'),
      );
    });

    test('supports Synced status and server version', () {
      expect(
        source,
        contains('Future<void> markSynced('),
      );
      expect(
        source,
        contains("'sync_status': 'SYNCED'"),
      );
      expect(
        source,
        contains(
          "'server_version': serverVersion",
        ),
      );
    });

    test('rejects negative server versions', () {
      expect(
        source,
        contains('if (serverVersion < 0)'),
      );
    });

    test('supports Error status', () {
      expect(
        source,
        contains('Future<void> markSyncError('),
      );
      expect(
        source,
        contains('MasterSyncStatus.error'),
      );
    });

    test('supports remote upsert', () {
      expect(
        source,
        contains('Future<void> upsertRemote('),
      );
      expect(
        source,
        contains(
          'syncStatus: MasterSyncStatus.synced',
        ),
      );
    });
  });

  group('Ingredient DAO data isolation', () {
    test('does not update Ingredient Inventory', () {
      expect(
        source,
        isNot(contains(
          "database.update(\n"
          "      'ingredient_inventory'",
        )),
      );
    });

    test('does not insert Ingredient movements', () {
      expect(
        source,
        isNot(contains(
          "database.insert(\n"
          "      'ingredient_movements'",
        )),
      );
    });

    test('does not delete Ingredient history', () {
      expect(
        source,
        isNot(contains(
          "database.delete(\n"
          "      'ingredient_movements'",
        )),
      );
      expect(
        source,
        isNot(contains(
          "database.delete(\n"
          "      'ingredient_inventory'",
        )),
      );
    });
  });
}
