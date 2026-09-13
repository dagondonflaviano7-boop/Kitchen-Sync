import 'package:kitchen_sync/data/local/daos/product_dao.dart';
import 'package:kitchen_sync/data/local/daos/recipe_dao.dart';
import 'package:kitchen_sync/data/local/daos/sale_consumption_dao.dart';
import 'package:kitchen_sync/data/local/daos/sale_posting_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/sale_consumption.dart';
import 'package:kitchen_sync/domain/models/sale_posting.dart';
import 'package:kitchen_sync/domain/models/sale_posting_costing.dart';
import 'package:kitchen_sync/domain/services/sale_consumption_planner.dart';
import 'package:sqflite/sqflite.dart';

class SalePostingRepository {
  final ProductDao productDao;
  final RecipeDao recipeDao;
  final SalePostingDao salePostingDao;
  final SaleConsumptionDao saleConsumptionDao;
  final SaleConsumptionPlanner saleConsumptionPlanner;
  final SalePostingCostingPlanner salePostingCostingPlanner;

  const SalePostingRepository({
    this.productDao = const ProductDao(),
    this.recipeDao = const RecipeDao(),
    this.salePostingDao = const SalePostingDao(),
    this.saleConsumptionDao = const SaleConsumptionDao(),
    this.saleConsumptionPlanner = const SaleConsumptionPlanner(),
    this.salePostingCostingPlanner = const SalePostingCostingPlanner(),
  });

  Future<void> postSale(
    SalePostingRequest request,
  ) async {
    request.validate();

    final Database database = await AppDatabase.instance.database;

    return database.transaction(
      (Transaction transaction) async {
        final bool alreadyPosted = await salePostingDao.saleExists(
          transaction,
          storeId: request.storeId,
          transactionNumber: request.transactionNumber,
        );

        if (alreadyPosted) {
          throw StateError(
            'Sale has already been posted.',
          );
        }

        final List<SaleConsumptionPlan> plans = <SaleConsumptionPlan>[];

        for (final SalePostingItem item in request.items) {
          final Product? product = await productDao.findById(
            transaction,
            item.productId,
          );

          if (product == null) {
            throw StateError(
              'The Sale Product was not found or is inactive.',
            );
          }

          Recipe? recipe;

          if (product.inventoryMode == ProductInventoryMode.recipe) {
            final String recipeId = product.recipeId?.trim() ?? '';

            if (recipeId.isEmpty) {
              throw StateError(
                'The Sale Product does not have a linked Recipe.',
              );
            }

            recipe = await recipeDao.getRecipeById(
              transaction,
              product.recipeId!,
            );

            if (recipe == null) {
              throw StateError(
                'The linked Sale Recipe was not found.',
              );
            }
          }

          final SaleConsumptionRequest consumptionRequest =
              item.toConsumptionRequest(
            saleId: request.saleId,
            storeId: request.storeId,
            occurredAt: request.occurredAt,
            performedBy: request.cashierId,
            deviceId: request.deviceId,
          );

          final SaleConsumptionPlan plan = saleConsumptionPlanner.createPlan(
            request: consumptionRequest,
            product: product,
            recipe: recipe,
          );

          plan.validate();
          plans.add(plan);
        }

        final SalePostingCostingSnapshot costing =
            salePostingCostingPlanner.createSnapshot(
          request: request,
          plans: plans,
        );

        costing.validate();

        await salePostingDao.insertPosting(
          transaction,
          request,
          costing,
        );

        for (final SaleConsumptionPlan plan in plans) {
          await saleConsumptionDao.executePlan(
            transaction,
            plan,
          );
        }
      },
    );
  }
}
