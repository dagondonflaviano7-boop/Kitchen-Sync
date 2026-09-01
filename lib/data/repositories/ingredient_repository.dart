import 'package:kitchen_sync/data/local/daos/ingredient_dao.dart';
import 'package:kitchen_sync/data/local/daos/supplier_dao.dart';
import 'package:kitchen_sync/data/local/daos/unit_of_measure_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:sqflite/sqflite.dart';

class IngredientRepository {
  final IngredientDao ingredientDao;
  final UnitOfMeasureDao unitDao;
  final SupplierDao supplierDao;

  const IngredientRepository({
    this.ingredientDao = const IngredientDao(),
    this.unitDao = const UnitOfMeasureDao(),
    this.supplierDao = const SupplierDao(),
  });

  Future<List<Ingredient>> getIngredients({
    bool includeInactive = true,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return ingredientDao.findAll(
      database,
      includeInactive: includeInactive,
    );
  }

  Future<List<Ingredient>> searchIngredients(
    String query, {
    bool includeInactive = true,
    IngredientCategory? category,
    String? supplierId,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return ingredientDao.search(
      database,
      query,
      includeInactive: includeInactive,
      category: category,
      supplierId: supplierId,
    );
  }

  Future<Ingredient?> findIngredientById(
    String ingredientId,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return ingredientDao.findById(
      database,
      ingredientId,
    );
  }

  Future<Ingredient?> findIngredientBySku(
    String ingredientSku,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return ingredientDao.findBySku(
      database,
      ingredientSku,
    );
  }

  Future<Ingredient> saveIngredient(
    Ingredient ingredient, {
    required String currentUserId,
  }) async {
    ingredient.validate();

    final String authenticatedUserId = _requireAuthenticatedUserId(
      currentUserId,
    );

    final Database database = await AppDatabase.instance.database;

    return database.transaction(
      (Transaction transaction) async {
        final Ingredient? existing =
            await ingredientDao.findByIdIncludingDeleted(
          transaction,
          ingredient.id,
        );

        if (existing?.deletedAt != null) {
          throw StateError(
            'A deleted Ingredient cannot be edited. '
            'Restore it before making changes.',
          );
        }

        final bool duplicate = await ingredientDao.skuExists(
          transaction,
          ingredient.ingredientSku,
          excludingId: ingredient.id,
        );

        if (duplicate) {
          throw StateError(
            'An Ingredient with SKU '
            '${ingredient.ingredientSku.trim().toUpperCase()} '
            'already exists.',
          );
        }

        final UnitOfMeasure usageUnit = await _requireActiveUnit(
          transaction,
          ingredient.usageUnitCode,
          fieldName: 'Usage Unit',
        );

        UnitOfMeasure? purchaseUnit;

        final String purchaseUnitCode =
            ingredient.purchaseUnitCode?.trim() ?? '';

        if (purchaseUnitCode.isNotEmpty) {
          purchaseUnit = await _requireActiveUnit(
            transaction,
            purchaseUnitCode,
            fieldName: 'Purchase Unit',
          );
        }

        Supplier? supplier;

        final String supplierId = ingredient.primarySupplierId?.trim() ?? '';

        if (supplierId.isNotEmpty) {
          supplier = await _requireActiveSupplier(
            transaction,
            supplierId,
          );
        }

        final DateTime now = DateTime.now().toUtc();

        final Ingredient normalized = ingredient.copyWith(
          ingredientSku: ingredient.ingredientSku.trim().toUpperCase(),
          ingredientName: ingredient.ingredientName.trim(),
          usageUnitCode: usageUnit.code.trim().toUpperCase(),
          purchaseUnitCode: purchaseUnit?.code,
          clearPurchaseUnit: purchaseUnit == null,
          primarySupplierId: supplier?.id,
          supplierNameSnapshot: supplier?.supplierName,
          clearPrimarySupplier: supplier == null,
          createdAt: existing?.createdAt ?? ingredient.createdAt,
          updatedAt: now,
          createdBy: existing?.createdBy ?? authenticatedUserId,
          updatedBy: authenticatedUserId,
          syncStatus: MasterSyncStatus.pending,
          serverVersion: existing?.serverVersion ?? ingredient.serverVersion,
          clearDeletedAt: true,
        );

        normalized.validate();

        await ingredientDao.upsert(
          transaction,
          normalized,
        );

        return normalized;
      },
    );
  }

  Future<void> setIngredientActive(
    String ingredientId,
    bool active, {
    required String currentUserId,
  }) async {
    final String authenticatedUserId = _requireAuthenticatedUserId(
      currentUserId,
    );

    final Database database = await AppDatabase.instance.database;

    await ingredientDao.setActive(
      database,
      ingredientId,
      active,
      updatedBy: authenticatedUserId,
    );
  }

  Future<void> deleteIngredient(
    Ingredient ingredient, {
    required String currentUserId,
  }) async {
    final String authenticatedUserId = _requireAuthenticatedUserId(
      currentUserId,
    );

    final Database database = await AppDatabase.instance.database;

    await database.transaction(
      (Transaction transaction) async {
        final Ingredient? existing = await ingredientDao.findById(
          transaction,
          ingredient.id,
        );

        if (existing == null) {
          throw StateError(
            'The Ingredient record was not found.',
          );
        }

        final bool referenced = await ingredientDao.isReferenced(
          transaction,
          ingredient.id,
        );

        if (referenced) {
          throw StateError(
            'This Ingredient cannot be deleted because '
            'it is used by Recipe, Inventory, Receiving, '
            'Adjustment, or Movement records. '
            'Deactivate it instead.',
          );
        }

        await ingredientDao.softDelete(
          transaction,
          ingredient.id,
          deletedAt: DateTime.now().toUtc(),
          updatedBy: authenticatedUserId,
        );
      },
    );
  }

  Future<UnitOfMeasure> _requireActiveUnit(
    DatabaseExecutor database,
    String unitCode, {
    required String fieldName,
  }) async {
    final String normalizedCode = unitCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw FormatException(
        '$fieldName is required.',
      );
    }

    final UnitOfMeasure? unit = await unitDao.findByCode(
      database,
      normalizedCode,
    );

    if (unit == null) {
      throw StateError(
        '$fieldName $normalizedCode does not exist.',
      );
    }

    if (!unit.active || unit.deletedAt != null) {
      throw StateError(
        '$fieldName $normalizedCode is inactive. '
        'Select an active Unit.',
      );
    }

    return unit;
  }

  Future<Supplier> _requireActiveSupplier(
    DatabaseExecutor database,
    String supplierId,
  ) async {
    final String normalizedSupplierId = supplierId.trim();

    if (normalizedSupplierId.isEmpty) {
      throw const FormatException(
        'Supplier ID is required.',
      );
    }

    final Supplier? supplier = await supplierDao.findById(
      database,
      normalizedSupplierId,
    );

    if (supplier == null) {
      throw StateError(
        'The selected Supplier does not exist.',
      );
    }

    if (!supplier.active || supplier.deletedAt != null) {
      throw StateError(
        'The selected Supplier is inactive. '
        'Select an active Supplier.',
      );
    }

    return supplier;
  }

  String _requireAuthenticatedUserId(
    String currentUserId,
  ) {
    final String authenticatedUserId = currentUserId.trim();

    if (authenticatedUserId.isEmpty) {
      throw StateError(
        'Authenticated user identity is required.',
      );
    }

    return authenticatedUserId;
  }
}
