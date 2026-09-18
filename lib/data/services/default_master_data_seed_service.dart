import 'package:kitchen_sync/data/repositories/ingredient_repository.dart';
import 'package:kitchen_sync/data/repositories/product_repository.dart';
import 'package:kitchen_sync/data/repositories/recipe_repository.dart';
import 'package:kitchen_sync/data/repositories/supplier_repository.dart';
import 'package:kitchen_sync/data/repositories/unit_of_measure_repository.dart';
import 'package:kitchen_sync/data/services/master_data_auto_sync.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

class DefaultMasterDataSeedResult {
  final int createdUnits;
  final int createdSuppliers;
  final int createdIngredients;
  final int createdRecipes;
  final int createdProducts;

  final int skippedUnits;
  final int skippedSuppliers;
  final int skippedIngredients;
  final int skippedRecipes;
  final int skippedProducts;

  final int errors;
  final bool synchronizationRequested;

  const DefaultMasterDataSeedResult({
    required this.createdUnits,
    required this.createdSuppliers,
    required this.createdIngredients,
    required this.createdRecipes,
    required this.createdProducts,
    required this.skippedUnits,
    required this.skippedSuppliers,
    required this.skippedIngredients,
    required this.skippedRecipes,
    required this.skippedProducts,
    required this.errors,
    required this.synchronizationRequested,
  });

  int get createdTotal {
    return createdUnits +
        createdSuppliers +
        createdIngredients +
        createdRecipes +
        createdProducts;
  }

  int get skippedTotal {
    return skippedUnits +
        skippedSuppliers +
        skippedIngredients +
        skippedRecipes +
        skippedProducts;
  }

  int get processedTotal {
    return createdTotal + skippedTotal;
  }

  bool get successful {
    return errors == 0 && processedTotal == 100;
  }
}

class DefaultMasterDataSeedService {
  final UnitOfMeasureRepository unitRepository;
  final SupplierRepository supplierRepository;
  final IngredientRepository ingredientRepository;
  final RecipeRepository recipeRepository;
  final ProductRepository productRepository;

  const DefaultMasterDataSeedService({
    this.unitRepository = const UnitOfMeasureRepository(),
    this.supplierRepository = const SupplierRepository(),
    this.ingredientRepository = const IngredientRepository(),
    this.recipeRepository = const RecipeRepository(),
    this.productRepository = const ProductRepository(),
  });

  Future<DefaultMasterDataSeedResult> seed({
    required String currentUserId,
    bool synchronize = true,
  }) async {
    final String userId = currentUserId.trim();

    if (userId.isEmpty) {
      throw const FormatException(
        'Authenticated user identity is required.',
      );
    }

    final DateTime now = DateTime.now().toUtc();

    int createdUnits = 0;
    int createdSuppliers = 0;
    int createdIngredients = 0;
    int createdRecipes = 0;
    int createdProducts = 0;

    int skippedUnits = 0;
    int skippedSuppliers = 0;
    int skippedIngredients = 0;
    int skippedRecipes = 0;
    int skippedProducts = 0;

    int errors = 0;

    for (final UnitOfMeasure unit in _units(now)) {
      try {
        final List<UnitOfMeasure> existingUnits =
            await unitRepository.getUnits();

        final bool unitExists = existingUnits.any(
          (UnitOfMeasure existing) {
            return existing.id.trim() == unit.id.trim() ||
                existing.code.trim().toUpperCase() ==
                    unit.code.trim().toUpperCase();
          },
        );

        if (unitExists) {
          skippedUnits += 1;
          continue;
        }

        await unitRepository.saveUnit(unit);
        createdUnits += 1;
      } catch (_) {
        errors += 1;
      }
    }

    for (final Supplier supplier in _suppliers(
      now,
      userId,
    )) {
      try {
        final List<Supplier> existingSuppliers =
            await supplierRepository.getSuppliers();

        final bool supplierExists = existingSuppliers.any(
          (Supplier existing) {
            return existing.id.trim() == supplier.id.trim() ||
                existing.supplierCode.trim().toUpperCase() ==
                    supplier.supplierCode.trim().toUpperCase();
          },
        );

        if (supplierExists) {
          skippedSuppliers += 1;
          continue;
        }

        await supplierRepository.saveSupplier(supplier);
        createdSuppliers += 1;
      } catch (_) {
        errors += 1;
      }
    }

    for (final Ingredient ingredient in _ingredients(
      now,
      userId,
    )) {
      try {
        final List<Ingredient> existingIngredients =
            await ingredientRepository.getIngredients();

        final bool ingredientExists = existingIngredients.any(
          (Ingredient existing) {
            return existing.id.trim() == ingredient.id.trim() ||
                existing.ingredientSku.trim().toUpperCase() ==
                    ingredient.ingredientSku.trim().toUpperCase();
          },
        );

        if (ingredientExists) {
          skippedIngredients += 1;
          continue;
        }

        await ingredientRepository.saveIngredient(
          ingredient,
          currentUserId: userId,
        );

        createdIngredients += 1;
      } catch (_) {
        errors += 1;
      }
    }

    for (final Recipe recipe in _recipes(
      now,
      userId,
    )) {
      try {
        final bool existing = await recipeRepository.recipeCodeExists(
          recipe.recipeCode,
        );

        if (existing) {
          skippedRecipes += 1;
          continue;
        }

        await recipeRepository.createRecipe(
          recipe,
          currentUserId: userId,
        );

        createdRecipes += 1;
      } catch (_) {
        errors += 1;
      }
    }

    for (final Product product in _products(now)) {
      try {
        final Product? existing = await productRepository.findProductBySku(
          product.sku,
        );

        if (existing != null) {
          skippedProducts += 1;
          continue;
        }

        await productRepository.saveProduct(product);
        createdProducts += 1;
      } catch (_) {
        errors += 1;
      }
    }

    bool synchronizationRequested = false;

    if (synchronize && errors == 0) {
      await MasterDataAutoSync.instance.trigger(
        reason: MasterDataAutoSyncReason.manual,
        force: true,
      );

      synchronizationRequested = true;
    }

    return DefaultMasterDataSeedResult(
      createdUnits: createdUnits,
      createdSuppliers: createdSuppliers,
      createdIngredients: createdIngredients,
      createdRecipes: createdRecipes,
      createdProducts: createdProducts,
      skippedUnits: skippedUnits,
      skippedSuppliers: skippedSuppliers,
      skippedIngredients: skippedIngredients,
      skippedRecipes: skippedRecipes,
      skippedProducts: skippedProducts,
      errors: errors,
      synchronizationRequested: synchronizationRequested,
    );
  }

  List<UnitOfMeasure> _units(
    DateTime now,
  ) {
    return <UnitOfMeasure>[
      _unit('PC', 'Piece', UnitType.count, 'PC', 1, false, now),
      _unit('SERV', 'Serving', UnitType.count, 'SERV', 1, true, now),
      _unit('G', 'Gram', UnitType.weight, 'G', 1, true, now),
      _unit('KG', 'Kilogram', UnitType.weight, 'G', 1000, true, now),
      _unit('ML', 'Milliliter', UnitType.volume, 'ML', 1, true, now),
      _unit('L', 'Liter', UnitType.volume, 'ML', 1000, true, now),
      _unit('PACK', 'Pack', UnitType.packaging, 'PC', 1, false, now),
      _unit('BOX', 'Box', UnitType.packaging, 'PC', 1, false, now),
      _unit('CAN', 'Can', UnitType.packaging, 'PC', 1, false, now),
      _unit('BOTTLE', 'Bottle', UnitType.packaging, 'PC', 1, false, now),
    ];
  }

  UnitOfMeasure _unit(
    String code,
    String name,
    UnitType type,
    String baseCode,
    double factor,
    bool decimal,
    DateTime now,
  ) {
    return UnitOfMeasure(
      id: 'seed-unit-${code.toLowerCase()}',
      code: code,
      name: name,
      unitType: type,
      baseUnitCode: baseCode,
      conversionFactor: factor,
      allowDecimal: decimal,
      active: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Supplier> _suppliers(
    DateTime now,
    String userId,
  ) {
    const List<String> names = <String>[
      'Cebu Fresh Produce',
      'Visayas Meat Supply',
      'Island Poultry Trading',
      'Mactan Seafood Depot',
      'Central Dairy Distribution',
      'Golden Grain Wholesale',
      'Kitchen Essentials Trading',
      'Beverage Partners Cebu',
      'Food Packaging Solutions',
      'Clean Kitchen Supplies',
    ];

    return List<Supplier>.generate(
      names.length,
      (int index) {
        final int number = index + 1;
        final String code = 'SUP${number.toString().padLeft(3, '0')}';

        return Supplier(
          id: 'seed-supplier-${number.toString().padLeft(3, '0')}',
          supplierCode: code,
          supplierName: names[index],
          contactPerson: 'Supplier Contact $number',
          phone: '0917000${number.toString().padLeft(4, '0')}',
          email: 'supplier$number@example.com',
          address: 'Cebu, Philippines',
          taxId: null,
          paymentTerms: '30 Days',
          leadTimeDays: 2 + index % 5,
          active: true,
          createdAt: now,
          updatedAt: now,
          createdBy: userId,
          updatedBy: userId,
        );
      },
      growable: false,
    );
  }

  List<Ingredient> _ingredients(
    DateTime now,
    String userId,
  ) {
    const List<String> names = <String>[
      'Chicken Breast',
      'Chicken Thigh',
      'Ground Pork',
      'Pork Belly',
      'Beef Sirloin',
      'Beef Ground',
      'Fresh Shrimp',
      'Fish Fillet',
      'White Rice',
      'Brown Rice',
      'All Purpose Flour',
      'Cornstarch',
      'White Sugar',
      'Brown Sugar',
      'Table Salt',
      'Black Pepper',
      'Garlic',
      'Red Onion',
      'Ginger',
      'Carrot',
      'Potato',
      'Cabbage',
      'Tomato',
      'Bell Pepper',
      'Spring Onion',
      'Cooking Oil',
      'Soy Sauce',
      'Oyster Sauce',
      'Vinegar',
      'Tomato Sauce',
      'Mayonnaise',
      'Butter',
      'Fresh Milk',
      'Cheddar Cheese',
      'Egg',
      'Bread Crumbs',
      'Pasta Noodles',
      'Coffee Powder',
      'Chocolate Powder',
      'Drinking Water',
    ];

    return List<Ingredient>.generate(
      names.length,
      (int index) {
        final int number = index + 1;
        final String sequence = number.toString().padLeft(3, '0');

        final bool liquid = index >= 25 && index <= 32;
        final bool count = names[index] == 'Egg';

        final String usageUnit = count
            ? 'PC'
            : liquid
                ? 'ML'
                : 'G';

        final String purchaseUnit = count
            ? 'PACK'
            : liquid
                ? 'L'
                : 'KG';

        final double factor = count ? 12 : 1000;

        final int supplierNumber = index % 10 + 1;

        return Ingredient(
          id: 'seed-ingredient-$sequence',
          ingredientSku: 'ING$sequence',
          ingredientName: names[index],
          category: _ingredientCategory(index),
          primarySupplierId:
              'seed-supplier-${supplierNumber.toString().padLeft(3, '0')}',
          supplierNameSnapshot: _supplierName(supplierNumber),
          usageUnitCode: usageUnit,
          purchaseUnitCode: purchaseUnit,
          conversionFactor: factor,
          latestPurchaseCost: 0.05 + index * 0.015,
          reorderLevel: count ? 24 : 1000,
          parLevel: count ? 120 : 5000,
          active: true,
          notes: 'Default Kitchen Sync development ingredient.',
          imagePath: null,
          createdAt: now,
          updatedAt: now,
          createdBy: userId,
          updatedBy: userId,
        );
      },
      growable: false,
    );
  }

  IngredientCategory _ingredientCategory(
    int index,
  ) {
    if (index <= 1) {
      return IngredientCategory.poultry;
    }

    if (index <= 5) {
      return IngredientCategory.meat;
    }

    if (index <= 7) {
      return IngredientCategory.seafood;
    }

    if (index <= 13) {
      return IngredientCategory.riceAndGrains;
    }

    if (index <= 18) {
      return IngredientCategory.spicesAndSeasonings;
    }

    if (index <= 24) {
      return IngredientCategory.vegetables;
    }

    if (index <= 30) {
      return IngredientCategory.saucesAndCondiments;
    }

    if (index <= 34) {
      return IngredientCategory.dairy;
    }

    if (index <= 36) {
      return IngredientCategory.dryGoods;
    }

    return IngredientCategory.beverages;
  }

  String _supplierName(
    int number,
  ) {
    const List<String> names = <String>[
      'Cebu Fresh Produce',
      'Visayas Meat Supply',
      'Island Poultry Trading',
      'Mactan Seafood Depot',
      'Central Dairy Distribution',
      'Golden Grain Wholesale',
      'Kitchen Essentials Trading',
      'Beverage Partners Cebu',
      'Food Packaging Solutions',
      'Clean Kitchen Supplies',
    ];

    return names[number - 1];
  }

  List<Recipe> _recipes(
    DateTime now,
    String userId,
  ) {
    const List<String> names = <String>[
      'Chicken Fried Rice',
      'Pork Fried Rice',
      'Beef Rice Bowl',
      'Garlic Chicken',
      'Soy Chicken',
      'Pork Adobo',
      'Beef Stir Fry',
      'Shrimp Rice Bowl',
      'Fish Fillet Meal',
      'Creamy Pasta',
      'Cheese Pasta',
      'Vegetable Stir Fry',
      'Chocolate Drink',
      'Iced Coffee',
      'House Sauce',
    ];

    return List<Recipe>.generate(
      names.length,
      (int index) {
        final int number = index + 1;
        final String sequence = number.toString().padLeft(3, '0');
        final String recipeId = 'seed-recipe-$sequence';

        final List<int> ingredientIndexes = <int>[
          index % 25,
          (index + 8) % 35,
          (index + 16) % 40,
        ];

        return Recipe(
          id: recipeId,
          recipeCode: 'RCP$sequence',
          recipeName: names[index],
          category: index >= 12
              ? RecipeCategory.beverage
              : index == 14
                  ? RecipeCategory.sauce
                  : RecipeCategory.mainDish,
          yieldQuantity: index >= 12 ? 1 : 4,
          yieldUnitCode: index >= 12 ? 'SERV' : 'SERV',
          active: true,
          ingredients: ingredientIndexes.map(
            (int ingredientIndex) {
              final int ingredientNumber = ingredientIndex + 1;
              final String ingredientSequence =
                  ingredientNumber.toString().padLeft(3, '0');

              return RecipeIngredient(
                id: '$recipeId:ingredient-$ingredientSequence',
                recipeId: recipeId,
                ingredientId: 'seed-ingredient-$ingredientSequence',
                ingredientSku: 'ING$ingredientSequence',
                ingredientName: _ingredientName(ingredientIndex),
                usageUnitCode: _ingredientUsageUnit(ingredientIndex),
                quantityRequired: _ingredientUsageUnit(ingredientIndex) == 'PC'
                    ? 1
                    : 50 + ingredientIndex * 2,
                costPerUsageUnit: 0.05 + ingredientIndex * 0.015,
              );
            },
          ).toList(growable: false),
          createdAt: now,
          updatedAt: now,
          createdBy: userId,
          updatedBy: userId,
        );
      },
      growable: false,
    );
  }

  String _ingredientName(
    int index,
  ) {
    return _ingredients(
      DateTime.utc(2000),
      'SEED',
    )[index]
        .ingredientName;
  }

  String _ingredientUsageUnit(
    int index,
  ) {
    if (index == 34) {
      return 'PC';
    }

    if (index >= 25 && index <= 32) {
      return 'ML';
    }

    return 'G';
  }

  List<Product> _products(
    DateTime now,
  ) {
    const List<String> recipeNames = <String>[
      'Chicken Fried Rice',
      'Pork Fried Rice',
      'Beef Rice Bowl',
      'Garlic Chicken',
      'Soy Chicken',
      'Pork Adobo',
      'Beef Stir Fry',
      'Shrimp Rice Bowl',
      'Fish Fillet Meal',
      'Creamy Pasta',
      'Cheese Pasta',
      'Vegetable Stir Fry',
      'Chocolate Drink',
      'Iced Coffee',
      'House Sauce',
    ];

    final List<Product> products = <Product>[];

    for (int index = 0; index < recipeNames.length; index++) {
      final int number = index + 1;
      final String sequence = number.toString().padLeft(3, '0');

      products.add(
        Product(
          id: 'seed-product-$sequence',
          sku: 'PRD$sequence',
          barcode: '480000000$sequence',
          productName: recipeNames[index],
          department: 'FOOD',
          departmentName: 'Prepared Food',
          classCode: 'MEALS',
          className: 'Kitchen Meals',
          subclass: 'PREPARED',
          subclassName: 'Prepared Items',
          brandName: 'Kitchen Sync',
          productUsage: 'Sale Item',
          description: 'Default Recipe-based development Product.',
          cost: 45 + index * 3,
          retailPrice: 75 + index * 5,
          vat: 0,
          active: true,
          inventoryMode: ProductInventoryMode.recipe,
          costingMethod: ProductCostingMethod.ingredient,
          recipeId: 'seed-recipe-$sequence',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    const List<String> directNames = <String>[
      'Bottled Water',
      'Canned Soda',
      'Packaged Juice',
      'Disposable Spoon Set',
      'Takeout Container',
      'Paper Cup',
      'Coffee Sachet',
      'Chocolate Sachet',
      'Extra Rice Pack',
      'Bread Roll',
    ];

    for (int index = 0; index < directNames.length; index++) {
      final int number = index + 16;
      final String sequence = number.toString().padLeft(3, '0');

      products.add(
        Product(
          id: 'seed-product-$sequence',
          sku: 'PRD$sequence',
          barcode: '480000000$sequence',
          productName: directNames[index],
          department: 'RETAIL',
          departmentName: 'Direct Sale Items',
          classCode: 'DIRECT',
          className: 'Direct Inventory',
          subclass: 'GENERAL',
          subclassName: 'General Merchandise',
          brandName: 'Kitchen Sync',
          productUsage: 'Sale Item',
          description: 'Default direct-inventory development Product.',
          cost: 8 + index * 2,
          retailPrice: 15 + index * 3,
          vat: 0,
          active: true,
          inventoryMode: ProductInventoryMode.direct,
          costingMethod: ProductCostingMethod.manual,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return List<Product>.unmodifiable(products);
  }
}
