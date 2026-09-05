import 'package:kitchen_sync/data/local/daos/product_dao.dart';
import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:sqflite/sqflite.dart';

class ProductRepository {
  final ProductDao productDao;
  final RecipeDao recipeDao;

  const ProductRepository({
    this.productDao = const ProductDao(),
    this.recipeDao = const RecipeDao(),
  });

  Future<List<Product>> getProducts({
    bool includeInactive = true,
    ProductInventoryMode? inventoryMode,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return productDao.findAll(
      database,
      includeInactive: includeInactive,
      inventoryMode: inventoryMode,
    );
  }

  Future<List<Product>> searchProducts(
    String query, {
    bool includeInactive = true,
    ProductInventoryMode? inventoryMode,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return productDao.search(
      database,
      query,
      includeInactive: includeInactive,
      inventoryMode: inventoryMode,
    );
  }

  Future<Product?> findProductById(
    String productId,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return productDao.findById(
      database,
      productId,
    );
  }

  Future<Product?> findProductBySku(
    String productSku,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return productDao.findBySku(
      database,
      productSku,
    );
  }

  Future<Product?> findProductByBarcode(
    String barcode,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return productDao.findByBarcode(
      database,
      barcode,
    );
  }

  Future<List<Product>> findProductsByRecipeId(
    String recipeId, {
    bool includeInactive = false,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return productDao.findProductsByRecipeId(
      database,
      recipeId,
      includeInactive: includeInactive,
    );
  }

  Future<Product> saveProduct(
    Product product,
  ) async {
    product.validate();

    final Database database = await AppDatabase.instance.database;

    return database.transaction(
      (Transaction transaction) async {
        final Product? existing = await productDao.findByIdIncludingInactive(
          transaction,
          product.id,
        );

        if (existing?.isDeleted ?? false) {
          throw StateError(
            'A deleted Product cannot be edited.',
          );
        }

        final bool duplicateSku = await productDao.skuExists(
          transaction,
          product.sku,
          excludingId: product.id,
        );

        if (duplicateSku) {
          throw StateError(
            'A Product with SKU '
            '${product.sku.trim().toUpperCase()} '
            'already exists.',
          );
        }

        final String normalizedBarcode = product.barcode?.trim() ?? '';

        if (normalizedBarcode.isNotEmpty) {
          final bool duplicateBarcode = await productDao.barcodeExists(
            transaction,
            normalizedBarcode,
            excludingId: product.id,
          );

          if (duplicateBarcode) {
            throw StateError(
              'A Product with barcode '
              '$normalizedBarcode already exists.',
            );
          }
        }

        String? normalizedRecipeId;

        if (product.inventoryMode == ProductInventoryMode.recipe) {
          final Recipe recipe = await _requireActiveRecipe(
            transaction,
            product.recipeId,
          );

          normalizedRecipeId = recipe.id.trim();
        }

        final DateTime now = DateTime.now().toUtc();

        final Product normalized = product.copyWith(
          sku: product.sku.trim().toUpperCase(),
          barcode: normalizedBarcode.isEmpty ? null : normalizedBarcode,
          productName: product.productName.trim(),
          recipeId: normalizedRecipeId,
          createdAt: existing?.createdAt ?? product.createdAt,
          updatedAt: now,
          syncStatus: MasterSyncStatus.pending,
          serverVersion: existing?.serverVersion ?? product.serverVersion,
          clearDeletedAt: true,
        );

        normalized.validate();

        await productDao.upsert(
          transaction,
          normalized,
        );

        return normalized;
      },
    );
  }

  Future<void> setProductActive(
    String productId,
    bool active,
  ) async {
    final String normalizedId = productId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Product ID is required.',
      );
    }

    final Database database = await AppDatabase.instance.database;

    await database.transaction(
      (Transaction transaction) async {
        final Product? existing = await productDao.findByIdIncludingInactive(
          transaction,
          normalizedId,
        );

        if (existing == null) {
          throw StateError(
            'The Product record was not found.',
          );
        }

        if (active && existing.inventoryMode == ProductInventoryMode.recipe) {
          await _requireActiveRecipe(
            transaction,
            existing.recipeId,
          );
        }

        await productDao.setActive(
          transaction,
          normalizedId,
          active,
          updatedAt: DateTime.now().toUtc(),
        );
      },
    );
  }

  Future<Recipe> _requireActiveRecipe(
    DatabaseExecutor database,
    String? recipeId,
  ) async {
    final String normalizedRecipeId = recipeId?.trim() ?? '';

    if (normalizedRecipeId.isEmpty) {
      throw const FormatException(
        'Recipe ID is required when '
        'Inventory Mode is RECIPE.',
      );
    }

    final Recipe? recipe = await recipeDao.findByIdIncludingDeleted(
      database,
      normalizedRecipeId,
    );

    if (recipe == null) {
      throw StateError(
        'The selected Recipe was not found.',
      );
    }

    if (recipe.isDeleted) {
      throw StateError(
        'The selected Recipe has been deleted.',
      );
    }

    if (!recipe.active) {
      throw StateError(
        'The selected Recipe is inactive.',
      );
    }

    return recipe;
  }
}
