import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchen_sync/data/repositories/ingredient_repository.dart';
import 'package:kitchen_sync/data/repositories/recipe_repository.dart';
import 'package:kitchen_sync/data/repositories/unit_of_measure_repository.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';
import 'package:kitchen_sync/domain/models/recipe_ingredient.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;
  final String currentUserId;

  const RecipeFormScreen({
    super.key,
    this.recipe,
    required this.currentUserId,
  });

  @override
  State<RecipeFormScreen> createState() {
    return _RecipeFormScreenState();
  }
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final RecipeRepository _recipeRepository = const RecipeRepository();

  final IngredientRepository _ingredientRepository =
      const IngredientRepository();

  final UnitOfMeasureRepository _unitRepository =
      const UnitOfMeasureRepository();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _yieldController;

  RecipeCategory _category = RecipeCategory.mainDish;
  String? _yieldUnitCode;

  bool _active = true;
  bool _loadingReferences = true;
  bool _saving = false;
  bool _dirty = false;

  String? _referenceError;

  List<Ingredient> _ingredients = <Ingredient>[];
  List<UnitOfMeasure> _units = <UnitOfMeasure>[];
  List<RecipeIngredient> _lines = <RecipeIngredient>[];

  bool get _isEditing => widget.recipe != null;

  double get _yieldQuantity {
    return double.tryParse(
          _yieldController.text.trim(),
        ) ??
        0;
  }

  double get _totalRecipeCost {
    return _lines.fold(
      0,
      (
        double total,
        RecipeIngredient line,
      ) {
        return total + line.extendedCost;
      },
    );
  }

  double get _costPerServing {
    if (_yieldQuantity <= 0) {
      return 0;
    }

    return _totalRecipeCost / _yieldQuantity;
  }

  @override
  void initState() {
    super.initState();

    final Recipe? recipe = widget.recipe;

    _codeController = TextEditingController(
      text: recipe?.recipeCode ?? '',
    );

    _nameController = TextEditingController(
      text: recipe?.recipeName ?? '',
    );

    _yieldController = TextEditingController(
      text: recipe == null ? '1' : recipe.yieldQuantity.toString(),
    );

    if (recipe != null) {
      _category = recipe.category;
      _yieldUnitCode = recipe.yieldUnitCode;
      _active = recipe.active;

      _lines = List<RecipeIngredient>.from(
        recipe.ingredients,
      );
    }

    _loadReferences();
  }

  Future<void> _loadReferences() async {
    try {
      final List<Ingredient> ingredients =
          await _ingredientRepository.getIngredients(
        includeInactive: false,
      );

      final List<UnitOfMeasure> units = await _unitRepository.getUnits(
        includeInactive: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ingredients = ingredients;
        _units = units;
        _loadingReferences = false;
        _referenceError = null;

        if (_yieldUnitCode == null && units.isNotEmpty) {
          _yieldUnitCode = units.first.code;
        }
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load Recipe references: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingReferences = false;
        _referenceError = 'Unable to load Ingredients and Units.';
      });
    }
  }

  void _markDirty() {
    if (_dirty) {
      return;
    }

    setState(() {
      _dirty = true;
    });
  }

  String _newId(String prefix) {
    return '$prefix-'
        '${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _requiredText(
    String? value,
    String field,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }

    return null;
  }

  String? _positiveNumber(
    String? value,
    String field,
  ) {
    final double? number = double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || !number.isFinite || number <= 0) {
      return '$field must be greater than zero.';
    }

    return null;
  }

  String _categoryLabel(
    RecipeCategory category,
  ) {
    return switch (category) {
      RecipeCategory.mainDish => 'Main Dish',
      RecipeCategory.sideDish => 'Side Dish',
      RecipeCategory.beverage => 'Beverage',
      RecipeCategory.dessert => 'Dessert',
      RecipeCategory.sauce => 'Sauce',
      RecipeCategory.ingredientPrep => 'Ingredient Preparation',
    };
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _addIngredient() async {
    if (_ingredients.isEmpty) {
      _showMessage(
        'Create an active Ingredient first.',
      );
      return;
    }

    final RecipeIngredient? line = await showModalBottomSheet<RecipeIngredient>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return _RecipeIngredientEditor(
          ingredients: _ingredients,
          existingIngredientIds: _lines.map(
            (RecipeIngredient item) {
              return item.ingredientId;
            },
          ).toSet(),
          recipeId:
              widget.recipe?.id ?? _codeController.text.trim().toUpperCase(),
        );
      },
    );

    if (line == null || !mounted) {
      return;
    }

    setState(() {
      _lines.add(line);
      _dirty = true;
    });
  }

  void _removeIngredient(
    RecipeIngredient line,
  ) {
    setState(() {
      _lines.remove(line);
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving) {
      return true;
    }

    final bool? discard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_outlined,
          ),
          title: const Text(
            'Discard changes?',
          ),
          content: const Text(
            'Unsaved Recipe changes will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Keep Editing',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Discard',
              ),
            ),
          ],
        );
      },
    );

    return discard == true;
  }

  Future<void> _handleBack() async {
    final bool shouldLeave = await _confirmDiscard();

    if (shouldLeave && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _saveRecipe() async {
    if (_saving) {
      return;
    }

    final String userId = widget.currentUserId.trim();

    if (userId.isEmpty) {
      _showMessage(
        'Authenticated user identity is required.',
      );
      return;
    }

    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_yieldUnitCode == null || _yieldUnitCode!.trim().isEmpty) {
      _showMessage(
        'Yield Unit is required.',
      );
      return;
    }

    if (_lines.isEmpty) {
      _showMessage(
        'Add at least one Ingredient.',
      );
      return;
    }

    final String recipeId = widget.recipe?.id ?? _newId('recipe');

    final List<RecipeIngredient> normalizedLines = _lines.map(
      (RecipeIngredient line) {
        return line.copyWith(
          recipeId: recipeId,
        );
      },
    ).toList(growable: false);

    final Recipe recipe = Recipe(
      id: recipeId,
      recipeCode: _codeController.text.trim(),
      recipeName: _nameController.text.trim(),
      category: _category,
      yieldQuantity: _yieldQuantity,
      yieldUnitCode: _yieldUnitCode!,
      active: _active,
      ingredients: normalizedLines,
      createdAt: widget.recipe?.createdAt,
      updatedAt: widget.recipe?.updatedAt,
      createdBy: widget.recipe?.createdBy,
      updatedBy: widget.recipe?.updatedBy,
      syncStatus: widget.recipe?.syncStatus ?? MasterSyncStatus.pending,
      serverVersion: widget.recipe?.serverVersion ?? 0,
    );

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await _recipeRepository.updateRecipe(
          recipe,
          currentUserId: userId,
        );
      } else {
        await _recipeRepository.createRecipe(
          recipe,
          currentUserId: userId,
        );
      }

      if (!mounted) {
        return;
      }

      _dirty = false;
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to save Recipe: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        error.toString().replaceFirst(
              'Bad state: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _yieldController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (
        bool didPop,
        Object? result,
      ) async {
        if (!didPop) {
          await _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Recipe' : 'Add Recipe',
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingReferences) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_referenceError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _referenceError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loadingReferences = true;
                    _referenceError = null;
                  });

                  _loadReferences();
                },
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRecipeInformation(),
                const SizedBox(height: 20),
                _buildIngredientSection(),
                const SizedBox(height: 20),
                _buildCostSummary(),
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recipe Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _codeController,
              enabled: !_saving && !_isEditing,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9_-]'),
                ),
              ],
              decoration: InputDecoration(
                labelText: 'Recipe Code *',
                hintText: 'RCP-ADOBO-001',
                helperText: _isEditing
                    ? 'Recipe Code is locked '
                        'to protect references.'
                    : 'Letters, numbers, hyphens, '
                        'and underscores only.',
                prefixIcon: const Icon(
                  Icons.tag_outlined,
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (String? value) {
                return _requiredText(
                  value,
                  'Recipe Code',
                );
              },
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: !_saving,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Recipe Name *',
                hintText: 'Chicken Adobo',
                prefixIcon: Icon(
                  Icons.restaurant_menu,
                ),
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                return _requiredText(
                  value,
                  'Recipe Name',
                );
              },
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RecipeCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(
                  Icons.category_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              items: RecipeCategory.values.map(
                (RecipeCategory category) {
                  return DropdownMenuItem<RecipeCategory>(
                    value: category,
                    child: Text(
                      _categoryLabel(category),
                    ),
                  );
                },
              ).toList(growable: false),
              onChanged: _saving
                  ? null
                  : (RecipeCategory? value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _category = value;
                        _dirty = true;
                      });
                    },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                final bool compact = constraints.maxWidth < 600;

                final Widget quantityField = TextFormField(
                  controller: _yieldController,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Yield Quantity *',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  validator: (
                    String? value,
                  ) {
                    return _positiveNumber(
                      value,
                      'Yield Quantity',
                    );
                  },
                  onChanged: (_) {
                    _markDirty();
                    setState(() {});
                  },
                );

                final Widget unitField = DropdownButtonFormField<String>(
                  initialValue: _yieldUnitCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Yield Unit *',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  items: _units.map(
                    (UnitOfMeasure unit) {
                      return DropdownMenuItem<String>(
                        value: unit.code,
                        child: Text(
                          '${unit.code} | '
                          '${unit.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(growable: false),
                  validator: (
                    String? value,
                  ) {
                    return _requiredText(
                      value,
                      'Yield Unit',
                    );
                  },
                  onChanged: _saving
                      ? null
                      : (String? value) {
                          setState(() {
                            _yieldUnitCode = value;
                            _dirty = true;
                          });
                        },
                );

                if (compact) {
                  return Column(
                    children: [
                      quantityField,
                      const SizedBox(height: 16),
                      unitField,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: quantityField,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: unitField,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _active,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Active Recipe',
              ),
              subtitle: const Text(
                'Inactive Recipes remain '
                'available for history.',
              ),
              onChanged: _saving
                  ? null
                  : (bool value) {
                      setState(() {
                        _active = value;
                        _dirty = true;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recipe Ingredients',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Ingredient',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 28,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 42,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No Ingredients added.',
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add at least one Ingredient '
                        'to calculate Recipe cost.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._lines.map(
                (RecipeIngredient line) {
                  return Card.outlined(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            child: Icon(
                              Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.ingredientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  line.ingredientSku,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatQuantity(line.quantityRequired)} '
                                  '${line.usageUnitCode} × '
                                  '₱${line.costPerUsageUnit.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Line Cost',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₱${line.extendedCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Remove Ingredient',
                            onPressed: _saving
                                ? null
                                : () {
                                    _removeIngredient(
                                      line,
                                    );
                                  },
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cost Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 16,
              children: [
                _CostMetric(
                  label: 'Total Ingredients',
                  value: '${_lines.length}',
                  icon: Icons.inventory_2_outlined,
                ),
                _CostMetric(
                  label: 'Total Recipe Cost',
                  value: '₱${_totalRecipeCost.toStringAsFixed(2)}',
                  icon: Icons.receipt_long_outlined,
                ),
                _CostMetric(
                  label: 'Yield Quantity',
                  value: _yieldQuantity > 0
                      ? '${_formatQuantity(_yieldQuantity)} '
                          '${_yieldUnitCode ?? ''}'
                      : '0',
                  icon: Icons.restaurant_outlined,
                ),
                _CostMetric(
                  label: 'Cost per Serving',
                  value: '₱${_costPerServing.toStringAsFixed(2)}',
                  icon: Icons.calculate_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool compact = constraints.maxWidth < 480;

        final Widget cancelButton = OutlinedButton(
          onPressed: _saving ? null : _handleBack,
          child: const Text('Cancel'),
        );

        final Widget saveButton = FilledButton.icon(
          onPressed: _saving ? null : _saveRecipe,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.save_outlined,
                ),
          label: Text(
            _saving
                ? 'Saving...'
                : _isEditing
                    ? 'Update Recipe'
                    : 'Save Recipe',
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: saveButton,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: cancelButton,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            cancelButton,
            const SizedBox(width: 12),
            saveButton,
          ],
        );
      },
    );
  }
}

class _RecipeIngredientEditor extends StatefulWidget {
  final List<Ingredient> ingredients;
  final Set<String> existingIngredientIds;
  final String recipeId;

  const _RecipeIngredientEditor({
    required this.ingredients,
    required this.existingIngredientIds,
    required this.recipeId,
  });

  @override
  State<_RecipeIngredientEditor> createState() {
    return _RecipeIngredientEditorState();
  }
}

class _RecipeIngredientEditorState extends State<_RecipeIngredientEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  final TextEditingController _costController = TextEditingController();

  Ingredient? _ingredient;

  List<Ingredient> get _availableIngredients {
    return widget.ingredients.where(
      (Ingredient ingredient) {
        return !widget.existingIngredientIds.contains(ingredient.id);
      },
    ).toList(growable: false);
  }

  double get _quantity {
    return double.tryParse(
          _quantityController.text.trim(),
        ) ??
        0;
  }

  double get _cost {
    return double.tryParse(
          _costController.text.trim(),
        ) ??
        0;
  }

  double get _lineCost {
    return _quantity * _cost;
  }

  String? _positiveNumber(
    String? value,
    String field,
  ) {
    final double? number = double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || !number.isFinite || number <= 0) {
      return '$field must be greater than zero.';
    }

    return null;
  }

  String? _nonNegativeNumber(
    String? value,
    String field,
  ) {
    final double? number = double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || !number.isFinite || number < 0) {
      return '$field cannot be negative.';
    }

    return null;
  }

  void _save() {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate() || _ingredient == null) {
      return;
    }

    final Ingredient ingredient = _ingredient!;

    Navigator.of(context).pop(
      RecipeIngredient(
        id: 'recipe-line-'
            '${DateTime.now().microsecondsSinceEpoch}',
        recipeId: widget.recipeId,
        ingredientId: ingredient.id,
        ingredientSku: ingredient.ingredientSku,
        ingredientName: ingredient.ingredientName,
        usageUnitCode: ingredient.usageUnitCode,
        quantityRequired: _quantity,
        costPerUsageUnit: _cost,
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Ingredient> available = _availableIngredients;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.playlist_add,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Ingredient',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an Ingredient and enter '
                'the required quantity and cost.',
              ),
              const SizedBox(height: 20),
              if (available.isEmpty)
                const Card.outlined(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No additional Ingredients are '
                      'available. All active Ingredients '
                      'are already included.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                DropdownButtonFormField<Ingredient>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient *',
                    prefixIcon: Icon(
                      Icons.inventory_2_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: available.map(
                    (Ingredient ingredient) {
                      return DropdownMenuItem<Ingredient>(
                        value: ingredient,
                        child: Text(
                          '${ingredient.ingredientSku} | '
                          '${ingredient.ingredientName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(growable: false),
                  validator: (Ingredient? value) {
                    if (value == null) {
                      return 'Ingredient is required.';
                    }

                    return null;
                  },
                  onChanged: (Ingredient? value) {
                    setState(() {
                      _ingredient = value;

                      if (value != null) {
                        _costController.text =
                            value.latestPurchaseCost.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_ingredient != null) ...[
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.straighten),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Usage Unit: '
                              '${_ingredient!.usageUnitCode}',
                            ),
                          ),
                          Text(
                            _ingredient!.ingredientSku,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Quantity Required *',
                    hintText: '1.00',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    return _positiveNumber(
                      value,
                      'Quantity Required',
                    );
                  },
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cost per Usage Unit *',
                    hintText: '0.00',
                    prefixText: '₱ ',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    return _nonNegativeNumber(
                      value,
                      'Cost per Usage Unit',
                    );
                  },
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Extended Line Cost',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '₱${_lineCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    final bool compact = constraints.maxWidth < 420;

                    final Widget cancelButton = OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    );

                    final Widget addButton = FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add Ingredient',
                      ),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 48,
                            child: addButton,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 48,
                            child: cancelButton,
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        cancelButton,
                        const SizedBox(width: 12),
                        addButton,
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CostMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CostMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 205,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
