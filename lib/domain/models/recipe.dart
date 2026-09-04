import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

enum RecipeCategory {
  mainDish,
  sideDish,
  beverage,
  dessert,
  sauce,
  ingredientPrep,
}

class Recipe {
  final String id;
  final String recipeCode;
  final String recipeName;
  final RecipeCategory category;
  final double yieldQuantity;
  final String yieldUnitCode;
  final bool active;
  final List<RecipeIngredient> ingredients;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  final MasterSyncStatus syncStatus;
  final int serverVersion;
  final DateTime? deletedAt;

  Recipe({
    required this.id,
    required this.recipeCode,
    required this.recipeName,
    required this.category,
    required this.yieldQuantity,
    required this.yieldUnitCode,
    required this.active,
    required this.ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.updatedBy,
    this.syncStatus = MasterSyncStatus.pending,
    this.serverVersion = 0,
    this.deletedAt,
  })  : createdAt = createdAt ?? _epochUtc(),
        updatedAt = updatedAt ?? createdAt ?? _epochUtc();

  bool get isDeleted {
    return deletedAt != null;
  }

  double get totalRecipeCost {
    return ingredients.fold(
      0,
      (
        double total,
        RecipeIngredient ingredient,
      ) {
        return total + ingredient.extendedCost;
      },
    );
  }

  double get costPerServing {
    if (yieldQuantity <= 0) {
      return 0;
    }

    return totalRecipeCost / yieldQuantity;
  }

  void validate() {
    if (id.trim().isEmpty) {
      throw const FormatException(
        'Recipe ID is required.',
      );
    }

    if (recipeCode.trim().isEmpty) {
      throw const FormatException(
        'Recipe Code is required.',
      );
    }

    if (recipeName.trim().isEmpty) {
      throw const FormatException(
        'Recipe Name is required.',
      );
    }

    if (!yieldQuantity.isFinite || yieldQuantity <= 0) {
      throw const FormatException(
        'Yield Quantity must be greater than zero.',
      );
    }

    if (yieldUnitCode.trim().isEmpty) {
      throw const FormatException(
        'Yield Unit is required.',
      );
    }

    if (serverVersion < 0) {
      throw const FormatException(
        'Server version must be zero or greater.',
      );
    }

    if (deletedAt != null && active) {
      throw const FormatException(
        'A deleted Recipe cannot remain active.',
      );
    }

    final Set<String> ingredientIds = <String>{};

    for (final RecipeIngredient ingredient in ingredients) {
      ingredient.validate();

      if (ingredient.recipeId.trim() != id.trim()) {
        throw const FormatException(
          'Every Recipe Ingredient must belong '
          'to the Recipe being saved.',
        );
      }

      final String ingredientId = ingredient.ingredientId.trim();

      if (!ingredientIds.add(ingredientId)) {
        throw const FormatException(
          'The same Ingredient cannot be added '
          'to a Recipe more than once.',
        );
      }
    }
  }

  Map<String, Object?> toSqlite() {
    validate();

    return <String, Object?>{
      'id': id.trim(),
      'recipe_code': recipeCode.trim().toUpperCase(),
      'recipe_name': recipeName.trim(),
      'category': category.name,
      'yield_quantity': yieldQuantity,
      'yield_unit_code': yieldUnitCode.trim().toUpperCase(),
      'active': active ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'created_by': _optionalString(createdBy),
      'updated_by': _optionalString(updatedBy),
      'sync_status': masterSyncStatusToStorage(
        syncStatus,
      ),
      'server_version': serverVersion,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  factory Recipe.fromSqlite(
    Map<String, Object?> map,
  ) {
    final Recipe recipe = Recipe(
      id: _requiredString(
        map['id'],
        'id',
      ),
      recipeCode: _requiredString(
        map['recipe_code'],
        'recipe_code',
      ).toUpperCase(),
      recipeName: _requiredString(
        map['recipe_name'],
        'recipe_name',
      ),
      category: _recipeCategoryFromStorage(
        _requiredString(
          map['category'],
          'category',
        ),
      ),
      yieldQuantity: _positiveNumber(
        map['yield_quantity'],
        'yield_quantity',
      ),
      yieldUnitCode: _requiredString(
        map['yield_unit_code'],
        'yield_unit_code',
      ).toUpperCase(),
      active: _sqliteBool(
        map['active'],
        'active',
      ),
      ingredients: const <RecipeIngredient>[],
      createdAt: _requiredDateTime(
        map['created_at'] ?? '1970-01-01T00:00:00.000Z',
        'created_at',
      ),
      updatedAt: _requiredDateTime(
        map['updated_at'] ?? map['created_at'] ?? '1970-01-01T00:00:00.000Z',
        'updated_at',
      ),
      createdBy: _optionalString(
        map['created_by'],
      ),
      updatedBy: _optionalString(
        map['updated_by'],
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['sync_status']?.toString() ?? 'PENDING',
      ),
      serverVersion: _nonNegativeInteger(
        map['server_version'] ?? 0,
        'server_version',
      ),
      deletedAt: _optionalDateTime(
        map['deleted_at'],
      ),
    );

    recipe.validate();
    return recipe;
  }

  Map<String, Object?> toFirebase() {
    validate();

    final Map<String, Object?> ingredientMap = <String, Object?>{};

    for (final RecipeIngredient ingredient in ingredients) {
      ingredientMap[ingredient.id.trim()] = <String, Object?>{
        'id': ingredient.id.trim(),
        'recipeId': id.trim(),
        'ingredientId': ingredient.ingredientId.trim(),
        'ingredientSku': ingredient.ingredientSku.trim().toUpperCase(),
        'ingredientName': ingredient.ingredientName.trim(),
        'usageUnitCode': ingredient.usageUnitCode.trim().toUpperCase(),
        'quantityRequired': ingredient.quantityRequired,
        'costPerUsageUnit': ingredient.costPerUsageUnit,
      };
    }

    return <String, Object?>{
      'id': id.trim(),
      'recipeCode': recipeCode.trim().toUpperCase(),
      'recipeName': recipeName.trim(),
      'category': category.name,
      'yieldQuantity': yieldQuantity,
      'yieldUnitCode': yieldUnitCode.trim().toUpperCase(),
      'active': active,
      'ingredients': ingredientMap,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'createdBy': _optionalString(createdBy),
      'updatedBy': _optionalString(updatedBy),
      'syncStatus': masterSyncStatusToStorage(
        syncStatus,
      ),
      'serverVersion': serverVersion,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  factory Recipe.fromFirebase(
    String firebaseId,
    Map<Object?, Object?> map,
  ) {
    final String normalizedId = firebaseId.trim();

    if (normalizedId.isEmpty) {
      throw const FormatException(
        'Recipe Firebase ID is required.',
      );
    }

    final List<RecipeIngredient> recipeIngredients =
        _recipeIngredientsFromFirebase(
      normalizedId,
      map['ingredients'],
    );

    final Recipe recipe = Recipe(
      id: normalizedId,
      recipeCode: _requiredString(
        map['recipeCode'],
        'recipeCode',
      ).toUpperCase(),
      recipeName: _requiredString(
        map['recipeName'],
        'recipeName',
      ),
      category: _recipeCategoryFromStorage(
        _requiredString(
          map['category'],
          'category',
        ),
      ),
      yieldQuantity: _positiveNumber(
        map['yieldQuantity'],
        'yieldQuantity',
      ),
      yieldUnitCode: _requiredString(
        map['yieldUnitCode'],
        'yieldUnitCode',
      ).toUpperCase(),
      active: _firebaseBool(
        map['active'],
        'active',
      ),
      ingredients: recipeIngredients,
      createdAt: _requiredDateTime(
        map['createdAt'],
        'createdAt',
      ),
      updatedAt: _requiredDateTime(
        map['updatedAt'],
        'updatedAt',
      ),
      createdBy: _optionalString(
        map['createdBy'],
      ),
      updatedBy: _optionalString(
        map['updatedBy'],
      ),
      syncStatus: masterSyncStatusFromStorage(
        map['syncStatus']?.toString() ?? 'SYNCED',
      ),
      serverVersion: _nonNegativeInteger(
        map['serverVersion'] ?? 0,
        'serverVersion',
      ),
      deletedAt: _optionalDateTime(
        map['deletedAt'],
      ),
    );

    recipe.validate();
    return recipe;
  }

  Recipe copyWith({
    String? id,
    String? recipeCode,
    String? recipeName,
    RecipeCategory? category,
    double? yieldQuantity,
    String? yieldUnitCode,
    bool? active,
    List<RecipeIngredient>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool clearCreatedBy = false,
    String? updatedBy,
    bool clearUpdatedBy = false,
    MasterSyncStatus? syncStatus,
    int? serverVersion,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Recipe(
      id: id ?? this.id,
      recipeCode: recipeCode ?? this.recipeCode,
      recipeName: recipeName ?? this.recipeName,
      category: category ?? this.category,
      yieldQuantity: yieldQuantity ?? this.yieldQuantity,
      yieldUnitCode: yieldUnitCode ?? this.yieldUnitCode,
      active: active ?? this.active,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }
}

List<RecipeIngredient> _recipeIngredientsFromFirebase(
  String recipeId,
  Object? value,
) {
  if (value == null) {
    return const <RecipeIngredient>[];
  }

  if (value is! Map) {
    throw const FormatException(
      'Recipe Ingredients must be a map.',
    );
  }

  final Map<Object?, Object?> records = Map<Object?, Object?>.from(value);

  final List<RecipeIngredient> result = <RecipeIngredient>[];

  final Set<String> lineIds = <String>{};

  for (final MapEntry<Object?, Object?> entry in records.entries) {
    final Object? rawLine = entry.value;

    if (rawLine is! Map) {
      throw const FormatException(
        'Every Recipe Ingredient must be a map.',
      );
    }

    final Map<Object?, Object?> line = Map<Object?, Object?>.from(
      rawLine,
    );

    final String lineId = _requiredString(
      line['id'] ?? entry.key.toString(),
      'ingredient.id',
    );

    if (!lineIds.add(lineId)) {
      throw const FormatException(
        'Duplicate Recipe Ingredient ID.',
      );
    }

    result.add(
      RecipeIngredient(
        id: lineId,
        recipeId: recipeId,
        ingredientId: _requiredString(
          line['ingredientId'],
          'ingredient.ingredientId',
        ),
        ingredientSku: _requiredString(
          line['ingredientSku'],
          'ingredient.ingredientSku',
        ).toUpperCase(),
        ingredientName: _requiredString(
          line['ingredientName'],
          'ingredient.ingredientName',
        ),
        usageUnitCode: _requiredString(
          line['usageUnitCode'],
          'ingredient.usageUnitCode',
        ).toUpperCase(),
        quantityRequired: _positiveNumber(
          line['quantityRequired'],
          'ingredient.quantityRequired',
        ),
        costPerUsageUnit: _nonNegativeNumber(
          line['costPerUsageUnit'],
          'ingredient.costPerUsageUnit',
        ),
      ),
    );
  }

  return List<RecipeIngredient>.unmodifiable(
    result,
  );
}

double _nonNegativeNumber(
  Object? value,
  String fieldName,
) {
  final double? number = value is num
      ? value.toDouble()
      : double.tryParse(
          value?.toString() ?? '',
        );

  if (number == null || !number.isFinite || number < 0) {
    throw FormatException(
      '$fieldName must be zero or greater.',
    );
  }

  return number;
}

bool _firebaseBool(
  Object? value,
  String fieldName,
) {
  if (value is bool) {
    return value;
  }

  if (value == 1 || value?.toString().toLowerCase() == 'true') {
    return true;
  }

  if (value == 0 || value?.toString().toLowerCase() == 'false') {
    return false;
  }

  throw FormatException(
    '$fieldName must be a Boolean.',
  );
}

DateTime _epochUtc() {
  return DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
}

RecipeCategory _recipeCategoryFromStorage(
  String value,
) {
  return RecipeCategory.values.firstWhere(
    (RecipeCategory category) {
      return category.name == value.trim();
    },
    orElse: () {
      throw FormatException(
        'Unsupported Recipe category: $value',
      );
    },
  );
}

String _requiredString(
  Object? value,
  String fieldName,
) {
  final String result = value?.toString().trim() ?? '';

  if (result.isEmpty) {
    throw FormatException(
      '$fieldName is required.',
    );
  }

  return result;
}

String? _optionalString(Object? value) {
  final String result = value?.toString().trim() ?? '';

  return result.isEmpty ? null : result;
}

double _positiveNumber(
  Object? value,
  String fieldName,
) {
  final double? number = value is num
      ? value.toDouble()
      : double.tryParse(
          value?.toString() ?? '',
        );

  if (number == null || !number.isFinite || number <= 0) {
    throw FormatException(
      '$fieldName must be greater than zero.',
    );
  }

  return number;
}

int _nonNegativeInteger(
  Object? value,
  String fieldName,
) {
  final int? number = value is int
      ? value
      : int.tryParse(
          value?.toString() ?? '',
        );

  if (number == null || number < 0) {
    throw FormatException(
      '$fieldName must be zero or greater.',
    );
  }

  return number;
}

bool _sqliteBool(
  Object? value,
  String fieldName,
) {
  if (value == 1 || value == true) {
    return true;
  }

  if (value == 0 || value == false) {
    return false;
  }

  throw FormatException(
    '$fieldName must be 0 or 1.',
  );
}

DateTime _requiredDateTime(
  Object? value,
  String fieldName,
) {
  final DateTime? date = DateTime.tryParse(
    value?.toString() ?? '',
  );

  if (date == null) {
    throw FormatException(
      '$fieldName must be a valid date.',
    );
  }

  return date;
}

DateTime? _optionalDateTime(Object? value) {
  final String result = value?.toString().trim() ?? '';

  if (result.isEmpty) {
    return null;
  }

  final DateTime? date = DateTime.tryParse(result);

  if (date == null) {
    throw const FormatException(
      'The optional date must be a valid date.',
    );
  }

  return date;
}
