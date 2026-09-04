import 'package:kitchen_sync/domain/models/product.dart';
import 'package:sqflite/sqflite.dart';

class ProductDao {
  const ProductDao();

  Future<void> upsert(
    DatabaseExecutor database,
    Product product,
  ) async {
    product.validate();

    await database.insert(
      'products',
      product.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Product?> findById(
    DatabaseExecutor database,
    String productId,
  ) async {
    final String normalizedId = productId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Product ID is required.',
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: 'id = ? AND active = ?',
      whereArgs: <Object?>[
        normalizedId,
        1,
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Product.fromSqlite(
      rows.first,
    );
  }

  Future<Product?> findByIdIncludingInactive(
    DatabaseExecutor database,
    String productId,
  ) async {
    final String normalizedId = productId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Product ID is required.',
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Product.fromSqlite(
      rows.first,
    );
  }

  Future<Product?> findBySku(
    DatabaseExecutor database,
    String productSku,
  ) async {
    final String normalizedSku = productSku.trim().toUpperCase();

    if (normalizedSku.isEmpty) {
      throw const FormatException(
        'SKU is required.',
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: 'sku = ? AND active = ?',
      whereArgs: <Object?>[
        normalizedSku,
        1,
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Product.fromSqlite(
      rows.first,
    );
  }

  Future<Product?> findByBarcode(
    DatabaseExecutor database,
    String barcode,
  ) async {
    final String normalizedBarcode = barcode.trim();

    if (normalizedBarcode.isEmpty) {
      throw const FormatException(
        'Barcode is required.',
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: 'barcode = ? AND active = ?',
      whereArgs: <Object?>[
        normalizedBarcode,
        1,
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Product.fromSqlite(
      rows.first,
    );
  }

  Future<List<Product>> findAll(
    DatabaseExecutor database, {
    bool includeInactive = true,
    ProductInventoryMode? inventoryMode,
  }) async {
    final List<String> conditions = <String>[];
    final List<Object?> arguments = <Object?>[];

    if (!includeInactive) {
      conditions.add('active = ?');
      arguments.add(1);
    }

    if (inventoryMode != null) {
      conditions.add('inventory_mode = ?');
      arguments.add(
        productInventoryModeToStorage(
          inventoryMode,
        ),
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: '''
        product_name COLLATE NOCASE,
        sku
      ''',
    );

    return rows.map(Product.fromSqlite).toList(growable: false);
  }

  Future<List<Product>> search(
    DatabaseExecutor database,
    String query, {
    bool includeInactive = true,
    ProductInventoryMode? inventoryMode,
  }) async {
    final String searchText = query.trim();

    final List<String> conditions = <String>[];
    final List<Object?> arguments = <Object?>[];

    if (!includeInactive) {
      conditions.add('active = ?');
      arguments.add(1);
    }

    if (inventoryMode != null) {
      conditions.add('inventory_mode = ?');
      arguments.add(
        productInventoryModeToStorage(
          inventoryMode,
        ),
      );
    }

    if (searchText.isNotEmpty) {
      conditions.add(
        '''
        (
          sku LIKE ? COLLATE NOCASE
          OR barcode LIKE ? COLLATE NOCASE
          OR product_name LIKE ? COLLATE NOCASE
          OR department_name LIKE ? COLLATE NOCASE
          OR class_name LIKE ? COLLATE NOCASE
          OR subclass_name LIKE ? COLLATE NOCASE
          OR supplier_name LIKE ? COLLATE NOCASE
          OR brand_name LIKE ? COLLATE NOCASE
        )
        ''',
      );

      final String pattern = '%$searchText%';

      arguments.addAll(
        <Object?>[
          pattern,
          pattern,
          pattern,
          pattern,
          pattern,
          pattern,
          pattern,
          pattern,
        ],
      );
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: '''
        product_name COLLATE NOCASE,
        sku
      ''',
    );

    return rows.map(Product.fromSqlite).toList(growable: false);
  }

  Future<bool> skuExists(
    DatabaseExecutor database,
    String productSku, {
    String? excludingId,
  }) async {
    final String normalizedSku = productSku.trim().toUpperCase();

    if (normalizedSku.isEmpty) {
      throw const FormatException(
        'SKU is required.',
      );
    }

    String where = 'sku = ?';

    final List<Object?> arguments = <Object?>[
      normalizedSku,
    ];

    final String excludedId = excludingId?.trim() ?? '';

    if (excludedId.isNotEmpty) {
      where = '$where AND id != ?';
      arguments.add(excludedId);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      columns: const <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<bool> barcodeExists(
    DatabaseExecutor database,
    String barcode, {
    String? excludingId,
  }) async {
    final String normalizedBarcode = barcode.trim();

    if (normalizedBarcode.isEmpty) {
      throw const FormatException(
        'Barcode is required.',
      );
    }

    String where = 'barcode = ?';

    final List<Object?> arguments = <Object?>[
      normalizedBarcode,
    ];

    final String excludedId = excludingId?.trim() ?? '';

    if (excludedId.isNotEmpty) {
      where = '$where AND id != ?';
      arguments.add(excludedId);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      columns: const <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String productId,
    bool active, {
    DateTime? updatedAt,
  }) async {
    final String normalizedId = productId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Product ID is required.',
      );
    }

    final int updated = await database.update(
      'products',
      <String, Object?>{
        'active': active ? 1 : 0,
        'updated_at': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[
        normalizedId,
      ],
    );

    if (updated == 0) {
      throw StateError(
        'The Product record was not found.',
      );
    }
  }

  Future<List<Product>> findProductsByRecipeId(
    DatabaseExecutor database,
    String recipeId, {
    bool includeInactive = false,
  }) async {
    final String normalizedRecipeId = recipeId.trim();

    if (normalizedRecipeId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    final List<String> conditions = <String>[
      'recipe_id = ?',
    ];

    final List<Object?> arguments = <Object?>[
      normalizedRecipeId,
    ];

    if (!includeInactive) {
      conditions.add('active = ?');
      arguments.add(1);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'products',
      where: conditions.join(' AND '),
      whereArgs: arguments,
      orderBy: '''
        product_name COLLATE NOCASE,
        sku
      ''',
    );

    return rows.map(Product.fromSqlite).toList(growable: false);
  }
}
