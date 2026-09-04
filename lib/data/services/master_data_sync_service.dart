import 'package:kitchen_sync/core/connectivity/connectivity_service.dart';
import 'package:kitchen_sync/data/local/daos/ingredient_dao.dart';
import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';
import 'package:kitchen_sync/data/local/daos/supplier_dao.dart';
import 'package:kitchen_sync/data/local/daos/unit_of_measure_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/data/remote/master_data_remote_repository.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:sqflite/sqflite.dart';

class MasterDataSyncResult {
  final int uploadedUnits;
  final int uploadedSuppliers;
  final int uploadedIngredients;
  final int uploadedRecipes;
  final int downloadedUnits;
  final int downloadedSuppliers;
  final int downloadedIngredients;
  final int downloadedRecipes;
  final int preservedLocalChanges;
  final int errors;
  final bool offline;

  const MasterDataSyncResult({
    required this.uploadedUnits,
    required this.uploadedSuppliers,
    required this.uploadedIngredients,
    this.uploadedRecipes = 0,
    required this.downloadedUnits,
    required this.downloadedSuppliers,
    required this.downloadedIngredients,
    this.downloadedRecipes = 0,
    required this.preservedLocalChanges,
    required this.errors,
    this.offline = false,
  });

  const MasterDataSyncResult.offline()
      : uploadedUnits = 0,
        uploadedSuppliers = 0,
        uploadedIngredients = 0,
        uploadedRecipes = 0,
        downloadedUnits = 0,
        downloadedSuppliers = 0,
        downloadedIngredients = 0,
        downloadedRecipes = 0,
        preservedLocalChanges = 0,
        errors = 0,
        offline = true;

  bool get successful {
    return !offline && errors == 0;
  }
}

class MasterDataSyncService {
  final MasterDataRemoteRepository remoteRepository;
  final UnitOfMeasureDao unitDao;
  final SupplierDao supplierDao;
  final IngredientDao ingredientDao;
  final RecipeDao recipeDao;
  final ConnectivityService connectivityService;

  bool _running = false;

  MasterDataSyncService({
    MasterDataRemoteRepository? remoteRepository,
    this.unitDao = const UnitOfMeasureDao(),
    this.supplierDao = const SupplierDao(),
    this.ingredientDao = const IngredientDao(),
    this.recipeDao = const RecipeDao(),
    ConnectivityService? connectivityService,
  })  : remoteRepository = remoteRepository ?? MasterDataRemoteRepository(),
        connectivityService = connectivityService ?? ConnectivityService();

  bool get isRunning => _running;

  Future<MasterDataSyncResult> synchronize() async {
    if (_running) {
      throw StateError(
        'Master Data synchronization is already running.',
      );
    }

    final bool online = await connectivityService.isOnline;

    if (!online) {
      return const MasterDataSyncResult.offline();
    }

    _running = true;

    try {
      final Database database = await AppDatabase.instance.database;

      int uploadedUnits = 0;
      int uploadedSuppliers = 0;
      int uploadedIngredients = 0;
      int uploadedRecipes = 0;
      int downloadedUnits = 0;
      int downloadedSuppliers = 0;
      int downloadedIngredients = 0;
      int downloadedRecipes = 0;
      int preservedLocalChanges = 0;
      int errors = 0;

      final List<UnitOfMeasure> pendingUnits =
          await unitDao.findPending(database);

      for (final UnitOfMeasure unit in pendingUnits) {
        try {
          await unitDao.markSyncing(
            database,
            unit.id,
          );

          final int serverVersion = await remoteRepository.uploadUnit(
            unit,
          );

          await unitDao.markSynced(
            database,
            unit.id,
            serverVersion: serverVersion,
          );

          uploadedUnits += 1;
        } catch (_) {
          errors += 1;

          await unitDao.markSyncError(
            database,
            unit.id,
          );
        }
      }

      final List<Supplier> pendingSuppliers =
          await supplierDao.findPending(database);

      for (final Supplier supplier in pendingSuppliers) {
        try {
          await supplierDao.markSyncing(
            database,
            supplier.id,
          );

          final int serverVersion = await remoteRepository.uploadSupplier(
            supplier,
          );

          await supplierDao.markSynced(
            database,
            supplier.id,
            serverVersion: serverVersion,
          );

          uploadedSuppliers += 1;
        } catch (_) {
          errors += 1;

          await supplierDao.markSyncError(
            database,
            supplier.id,
          );
        }
      }

      final List<Ingredient> pendingIngredients =
          await ingredientDao.findPending(database);

      for (final Ingredient ingredient in pendingIngredients) {
        try {
          await ingredientDao.markSyncing(
            database,
            ingredient.id,
          );

          final int serverVersion = await remoteRepository.uploadIngredient(
            ingredient,
          );

          await ingredientDao.markSynced(
            database,
            ingredient.id,
            serverVersion: serverVersion,
          );

          uploadedIngredients += 1;
        } catch (_) {
          errors += 1;

          await ingredientDao.markSyncError(
            database,
            ingredient.id,
          );
        }
      }

      final List<Recipe> pendingRecipes = await recipeDao.findPending(database);

      for (final Recipe recipe in pendingRecipes) {
        try {
          await recipeDao.markSyncing(
            database,
            recipe.id,
          );

          final int serverVersion = await remoteRepository.uploadRecipe(
            recipe,
          );

          await recipeDao.markSynced(
            database,
            recipe.id,
            serverVersion: serverVersion,
          );

          uploadedRecipes += 1;
        } catch (_) {
          errors += 1;

          await recipeDao.markSyncError(
            database,
            recipe.id,
          );
        }
      }

      final List<UnitOfMeasure> remoteUnits =
          await remoteRepository.downloadUnits();

      for (final UnitOfMeasure remoteUnit in remoteUnits) {
        final UnitOfMeasure? localUnit = await unitDao.findByIdIncludingDeleted(
          database,
          remoteUnit.id,
        );

        if (_hasUnresolvedLocalUnit(localUnit)) {
          preservedLocalChanges += 1;
          continue;
        }

        if (_shouldApplyRemoteUnit(
          localUnit,
          remoteUnit,
        )) {
          await unitDao.upsertRemote(
            database,
            remoteUnit,
          );

          downloadedUnits += 1;
        }
      }

      final List<Supplier> remoteSuppliers =
          await remoteRepository.downloadSuppliers();

      for (final Supplier remoteSupplier in remoteSuppliers) {
        final Supplier? localSupplier =
            await supplierDao.findByIdIncludingDeleted(
          database,
          remoteSupplier.id,
        );

        if (_hasUnresolvedLocalSupplier(
          localSupplier,
        )) {
          preservedLocalChanges += 1;
          continue;
        }

        if (_shouldApplyRemoteSupplier(
          localSupplier,
          remoteSupplier,
        )) {
          await supplierDao.upsertRemote(
            database,
            remoteSupplier,
          );

          downloadedSuppliers += 1;
        }
      }

      final List<Ingredient> remoteIngredients =
          await remoteRepository.downloadIngredients();

      for (final Ingredient remoteIngredient in remoteIngredients) {
        final Ingredient? localIngredient =
            await ingredientDao.findByIdIncludingDeleted(
          database,
          remoteIngredient.id,
        );

        if (_hasUnresolvedLocalIngredient(
          localIngredient,
        )) {
          preservedLocalChanges += 1;
          continue;
        }

        if (_shouldApplyRemoteIngredient(
          localIngredient,
          remoteIngredient,
        )) {
          await ingredientDao.upsertRemote(
            database,
            remoteIngredient,
          );

          downloadedIngredients += 1;
        }
      }

      final List<Recipe> remoteRecipes =
          await remoteRepository.downloadRecipes();

      for (final Recipe remoteRecipe in remoteRecipes) {
        final Recipe? localRecipe = await recipeDao.findByIdIncludingDeleted(
          database,
          remoteRecipe.id,
        );

        if (_hasUnresolvedLocalRecipe(
          localRecipe,
        )) {
          preservedLocalChanges += 1;
          continue;
        }

        if (_shouldApplyRemoteRecipe(
          localRecipe,
          remoteRecipe,
        )) {
          await recipeDao.upsertRemote(
            database,
            remoteRecipe,
          );

          downloadedRecipes += 1;
        }
      }

      return MasterDataSyncResult(
        uploadedUnits: uploadedUnits,
        uploadedSuppliers: uploadedSuppliers,
        uploadedIngredients: uploadedIngredients,
        uploadedRecipes: uploadedRecipes,
        downloadedUnits: downloadedUnits,
        downloadedSuppliers: downloadedSuppliers,
        downloadedIngredients: downloadedIngredients,
        downloadedRecipes: downloadedRecipes,
        preservedLocalChanges: preservedLocalChanges,
        errors: errors,
      );
    } finally {
      _running = false;
    }
  }

  bool _hasUnresolvedLocalUnit(
    UnitOfMeasure? local,
  ) {
    if (local == null) {
      return false;
    }

    return local.syncStatus == MasterSyncStatus.pending ||
        local.syncStatus == MasterSyncStatus.syncing ||
        local.syncStatus == MasterSyncStatus.error;
  }

  bool _hasUnresolvedLocalSupplier(
    Supplier? local,
  ) {
    if (local == null) {
      return false;
    }

    return local.syncStatus == MasterSyncStatus.pending ||
        local.syncStatus == MasterSyncStatus.syncing ||
        local.syncStatus == MasterSyncStatus.error;
  }

  bool _hasUnresolvedLocalIngredient(
    Ingredient? local,
  ) {
    if (local == null) {
      return false;
    }

    return local.syncStatus == MasterSyncStatus.pending ||
        local.syncStatus == MasterSyncStatus.syncing ||
        local.syncStatus == MasterSyncStatus.error;
  }

  bool _hasUnresolvedLocalRecipe(
    Recipe? local,
  ) {
    if (local == null) {
      return false;
    }

    return local.syncStatus == MasterSyncStatus.pending ||
        local.syncStatus == MasterSyncStatus.syncing ||
        local.syncStatus == MasterSyncStatus.error;
  }

  bool _shouldApplyRemoteUnit(
    UnitOfMeasure? local,
    UnitOfMeasure remote,
  ) {
    if (local == null) {
      return true;
    }

    if (remote.serverVersion > local.serverVersion) {
      return true;
    }

    if (remote.serverVersion < local.serverVersion) {
      return false;
    }

    return remote.updatedAt.isAfter(
      local.updatedAt,
    );
  }

  bool _shouldApplyRemoteSupplier(
    Supplier? local,
    Supplier remote,
  ) {
    if (local == null) {
      return true;
    }

    if (remote.serverVersion > local.serverVersion) {
      return true;
    }

    if (remote.serverVersion < local.serverVersion) {
      return false;
    }

    return remote.updatedAt.isAfter(
      local.updatedAt,
    );
  }

  bool _shouldApplyRemoteIngredient(
    Ingredient? local,
    Ingredient remote,
  ) {
    if (local == null) {
      return true;
    }

    if (remote.serverVersion > local.serverVersion) {
      return true;
    }

    if (remote.serverVersion < local.serverVersion) {
      return false;
    }

    return remote.updatedAt.isAfter(
      local.updatedAt,
    );
  }

  bool _shouldApplyRemoteRecipe(
    Recipe? local,
    Recipe remote,
  ) {
    if (local == null) {
      return true;
    }

    if (remote.serverVersion > local.serverVersion) {
      return true;
    }

    if (remote.serverVersion < local.serverVersion) {
      return false;
    }

    return remote.updatedAt.isAfter(
      local.updatedAt,
    );
  }
}
