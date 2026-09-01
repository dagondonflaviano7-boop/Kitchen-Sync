import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchen_sync/data/repositories/ingredient_repository.dart';
import 'package:kitchen_sync/data/repositories/supplier_repository.dart';
import 'package:kitchen_sync/data/repositories/unit_of_measure_repository.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/data/services/master_data_auto_sync.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

class IngredientFormScreen extends StatefulWidget {
  final Ingredient? ingredient;
  final String currentUserId;

  const IngredientFormScreen({
    super.key,
    this.ingredient,
    required this.currentUserId,
  });

  @override
  State<IngredientFormScreen> createState() {
    return _IngredientFormScreenState();
  }
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  static const Color _surface = Color(0xFFF8F6F1);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _dirty = false;

  final IngredientRepository _ingredientRepository =
      const IngredientRepository();

  final UnitOfMeasureRepository _unitRepository =
      const UnitOfMeasureRepository();

  final SupplierRepository _supplierRepository = const SupplierRepository();

  final TextEditingController _skuController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _factorController =
      TextEditingController(text: '1');

  final TextEditingController _costController =
      TextEditingController(text: '0');

  final TextEditingController _reorderController =
      TextEditingController(text: '0');

  final TextEditingController _parController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  List<UnitOfMeasure> _activeUnits = <UnitOfMeasure>[];

  List<Supplier> _activeSuppliers = <Supplier>[];

  IngredientCategory _category = IngredientCategory.other;

  String? _supplierId;
  String? _purchaseUnitCode;
  String? _usageUnitCode;

  bool _active = true;
  bool _loadingReferences = true;
  String? _referenceError;

  bool get _isEditing {
    return widget.ingredient != null;
  }

  @override
  void initState() {
    super.initState();

    _initializeFields();
    _loadReferences();
  }

  void _initializeFields() {
    final Ingredient? ingredient = widget.ingredient;

    if (ingredient == null) {
      return;
    }

    _skuController.text = ingredient.ingredientSku;

    _nameController.text = ingredient.ingredientName;

    _factorController.text = _formatNumber(
      ingredient.conversionFactor,
    );

    _costController.text = _formatNumber(
      ingredient.latestPurchaseCost,
    );

    _reorderController.text = _formatNumber(
      ingredient.reorderLevel,
    );

    _parController.text = ingredient.parLevel == null
        ? ''
        : _formatNumber(
            ingredient.parLevel!,
          );

    _notesController.text = ingredient.notes ?? '';

    _category = ingredient.category;
    _supplierId = ingredient.primarySupplierId;
    _purchaseUnitCode = ingredient.purchaseUnitCode;
    _usageUnitCode = ingredient.usageUnitCode;
    _active = ingredient.active;
  }

  Future<void> _loadReferences() async {
    try {
      final List<UnitOfMeasure> units = await _unitRepository.getUnits(
        includeInactive: false,
      );

      final List<Supplier> suppliers = await _supplierRepository.getSuppliers(
        includeInactive: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeUnits = units
            .where(
              (UnitOfMeasure unit) => unit.active && unit.deletedAt == null,
            )
            .toList(growable: false);

        _activeSuppliers = suppliers
            .where(
              (Supplier supplier) =>
                  supplier.active && supplier.deletedAt == null,
            )
            .toList(growable: false);

        _loadingReferences = false;
        _referenceError = null;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Ingredient references failed to load: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingReferences = false;
        _referenceError = 'Unable to load Units and Suppliers.';
      });
    }
  }

  double get _costPerUsageUnit {
    final double purchaseCost = double.tryParse(
          _costController.text.trim(),
        ) ??
        0;

    final double conversionFactor = double.tryParse(
          _factorController.text.trim(),
        ) ??
        0;

    if (!purchaseCost.isFinite ||
        !conversionFactor.isFinite ||
        purchaseCost < 0 ||
        conversionFactor <= 0) {
      return 0;
    }

    return purchaseCost / conversionFactor;
  }

  void _markDirty() {
    if (_dirty) {
      return;
    }

    setState(() {
      _dirty = true;
    });
  }

  String? _validateSku(String? value) {
    final String sku = value?.trim() ?? '';

    if (sku.isEmpty) {
      return 'Ingredient SKU is required.';
    }

    if (sku.length < 3) {
      return 'Ingredient SKU must have at least 3 characters.';
    }

    if (sku.length > 40) {
      return 'Ingredient SKU cannot exceed 40 characters.';
    }

    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(sku)) {
      return 'Use only letters, numbers, hyphens, '
          'and underscores.';
    }

    return null;
  }

  String? _validateName(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Ingredient Name is required.';
    }

    if (name.length < 2) {
      return 'Ingredient Name must have at least 2 characters.';
    }

    if (name.length > 100) {
      return 'Ingredient Name cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validateUsageUnit(String? value) {
    final String code = value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Usage Unit is required.';
    }

    final bool exists = _activeUnits.any(
      (UnitOfMeasure unit) {
        return unit.code.toUpperCase() == code.toUpperCase();
      },
    );

    if (!exists) {
      return 'Select an active Usage Unit.';
    }

    return null;
  }

  String? _validatePurchaseUnit(String? value) {
    final String code = value?.trim() ?? '';

    if (code.isEmpty) {
      return null;
    }

    final bool exists = _activeUnits.any(
      (UnitOfMeasure unit) {
        return unit.code.toUpperCase() == code.toUpperCase();
      },
    );

    if (!exists) {
      return 'Select an active Purchase Unit.';
    }

    return null;
  }

  String? _validatePositiveNumber(
    String? value,
    String fieldName,
  ) {
    final String input = value?.trim() ?? '';

    if (input.isEmpty) {
      return '$fieldName is required.';
    }

    final double? number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName.';
    }

    if (number <= 0) {
      return '$fieldName must be greater than zero.';
    }

    return null;
  }

  String? _validateNonNegativeNumber(
    String? value,
    String fieldName,
  ) {
    final String input = value?.trim() ?? '';

    if (input.isEmpty) {
      return '$fieldName is required.';
    }

    final double? number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName.';
    }

    if (number < 0) {
      return '$fieldName cannot be negative.';
    }

    return null;
  }

  String? _validateParLevel(String? value) {
    final String input = value?.trim() ?? '';

    if (input.isEmpty) {
      return null;
    }

    final double? parLevel = double.tryParse(input);

    if (parLevel == null || !parLevel.isFinite) {
      return 'Enter a valid Par Level.';
    }

    if (parLevel < 0) {
      return 'Par Level cannot be negative.';
    }

    final double? reorderLevel = double.tryParse(
      _reorderController.text.trim(),
    );

    if (reorderLevel != null &&
        reorderLevel.isFinite &&
        parLevel < reorderLevel) {
      return 'Par Level cannot be lower than Reorder Level.';
    }

    return null;
  }

  String? _validateNotes(String? value) {
    final String notes = value?.trim() ?? '';

    if (notes.length > 500) {
      return 'Notes cannot exceed 500 characters.';
    }

    return null;
  }

  String _conversionHelperText() {
    final String purchaseUnit = _purchaseUnitCode ?? 'Purchase Unit';

    final String usageUnit = _usageUnitCode ?? 'Usage Unit';

    final String factor = _factorController.text.trim().isEmpty
        ? '1'
        : _factorController.text.trim();

    return '1 $purchaseUnit = $factor $usageUnit';
  }

  double? _parseOptionalNumber(
    String value,
  ) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return double.parse(normalized);
  }

  String? _optionalValue(String value) {
    final String normalized = value.trim();

    return normalized.isEmpty ? null : normalized;
  }

  Supplier? _findSelectedSupplier() {
    final String? selectedId = _supplierId;

    if (selectedId == null || selectedId.trim().isEmpty) {
      return null;
    }

    for (final Supplier supplier in _activeSuppliers) {
      if (supplier.id == selectedId) {
        return supplier;
      }
    }

    return null;
  }

  void _showSaveError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _saveIngredient() async {
    if (_saving || _loadingReferences) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      _showSaveError(
        'Please correct the highlighted fields.',
      );
      return;
    }

    final String userId = widget.currentUserId.trim();

    if (userId.isEmpty) {
      _showSaveError(
        'Authenticated user identity is required.',
      );
      return;
    }

    final String? usageUnitCode = _usageUnitCode;

    if (usageUnitCode == null || usageUnitCode.trim().isEmpty) {
      _showSaveError(
        'Usage Unit is required.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final DateTime now = DateTime.now().toUtc();

      final Ingredient? original = widget.ingredient;

      final Supplier? supplier = _findSelectedSupplier();

      final Ingredient ingredient = Ingredient(
        id: original?.id ??
            'ingredient-'
                '${now.microsecondsSinceEpoch}',
        ingredientSku: _skuController.text.trim().toUpperCase(),
        ingredientName: _nameController.text.trim(),
        category: _category,
        primarySupplierId: supplier?.id,
        supplierNameSnapshot: supplier?.supplierName,
        usageUnitCode: usageUnitCode.trim().toUpperCase(),
        purchaseUnitCode: _purchaseUnitCode,
        conversionFactor: double.parse(
          _factorController.text.trim(),
        ),
        latestPurchaseCost: double.parse(
          _costController.text.trim(),
        ),
        reorderLevel: double.parse(
          _reorderController.text.trim(),
        ),
        parLevel: _parseOptionalNumber(
          _parController.text,
        ),
        active: _active,
        notes: _optionalValue(
          _notesController.text,
        ),
        imagePath: original?.imagePath,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
        createdBy: original?.createdBy ?? userId,
        updatedBy: userId,
        syncStatus: MasterSyncStatus.pending,
        serverVersion: original?.serverVersion ?? 0,
        deletedAt: original?.deletedAt,
      );

      ingredient.validate();

      await _ingredientRepository.saveIngredient(
        ingredient,
        currentUserId: userId,
      );

      unawaited(
        MasterDataAutoSync.instance.trigger(
          reason: MasterDataAutoSyncReason.ingredientSaved,
        ),
      );

      if (!mounted) {
        return;
      }

      _dirty = false;

      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      _showSaveError(error.message);
    } on FormatException catch (error) {
      _showSaveError(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        'Ingredient save failed: '
        '$error\n$stackTrace',
      );

      _showSaveError(
        'Unable to save the Ingredient. '
        'Please try again.',
      );
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (_saving) {
      return false;
    }

    if (!_dirty) {
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
            Icons.warning_amber_rounded,
            color: Color(0xFFA15C22),
            size: 34,
          ),
          title: const Text(
            'Discard changes?',
          ),
          content: const Text(
            'The changes made to this Ingredient '
            'have not been saved.',
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Discard',
              ),
            ),
          ],
        );
      },
    );

    return discard ?? false;
  }

  Future<void> _handleBackNavigation() async {
    if (_saving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool canLeave = await _confirmDiscardChanges();

    if (!canLeave || !mounted) {
      return;
    }

    Navigator.of(context).pop(false);
  }

  Widget _buildCostPreview() {
    final double purchaseCost = double.tryParse(
          _costController.text.trim(),
        ) ??
        0;

    final double factor = double.tryParse(
          _factorController.text.trim(),
        ) ??
        0;

    final bool valid = purchaseCost.isFinite &&
        factor.isFinite &&
        purchaseCost >= 0 &&
        factor > 0;

    final String purchaseUnit = _purchaseUnitCode ?? 'Purchase Unit';

    final String usageUnit = _usageUnitCode ?? 'Usage Unit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFD8C8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_outlined,
            color: Color(0xFF2E6B4F),
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cost per Usage Unit',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  valid
                      ? '₱${_costPerUsageUnit.toStringAsFixed(4)} '
                          'per $usageUnit'
                      : 'Enter a valid cost and factor.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: valid
                        ? const Color(0xFF183027)
                        : const Color(0xFFB42318),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  valid
                      ? '₱${purchaseCost.toStringAsFixed(2)} '
                          'per $purchaseUnit ÷ '
                          '${_formatNumber(factor)}'
                      : 'Conversion Factor must be '
                          'greater than zero.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _factorController.dispose();
    _costController.dispose();
    _reorderController.dispose();
    _parController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (
        bool didPop,
        Object? result,
      ) {
        if (!didPop) {
          unawaited(
            _handleBackNavigation(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _saving ? null : _handleBackNavigation,
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: Text(
            _isEditing ? 'Edit Ingredient' : 'Add Ingredient',
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
                icon: const Icon(Icons.refresh),
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
            maxWidth: 900,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Update Ingredient' : 'Create Ingredient',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _skuController,
                  enabled: !_saving && !_isEditing,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9_-]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Ingredient SKU *',
                    hintText: 'ING-CHICKEN-001',
                    helperText: _isEditing
                        ? 'SKU is locked to protect references.'
                        : 'Letters, numbers, hyphens, '
                            'and underscores only.',
                    prefixIcon: const Icon(Icons.tag),
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateSku,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient Name *',
                    hintText: 'Chicken Breast',
                    prefixIcon: Icon(Icons.restaurant_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<IngredientCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: IngredientCategory.values.map(
                    (IngredientCategory category) {
                      return DropdownMenuItem<IngredientCategory>(
                        value: category,
                        child: Text(
                          ingredientCategoryLabel(
                            category,
                          ),
                        ),
                      );
                    },
                  ).toList(growable: false),
                  onChanged: _saving
                      ? null
                      : (IngredientCategory? value) {
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
                DropdownButtonFormField<String?>(
                  initialValue: _supplierId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Primary Supplier',
                    prefixIcon: Icon(
                      Icons.local_shipping_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No primary Supplier'),
                    ),
                    ..._activeSuppliers.map(
                      (Supplier supplier) {
                        return DropdownMenuItem<String?>(
                          value: supplier.id,
                          child: Text(
                            '${supplier.supplierCode} | '
                            '${supplier.supplierName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (String? value) {
                          setState(() {
                            _supplierId = value;
                            _dirty = true;
                          });
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _purchaseUnitCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Unit',
                    prefixIcon: Icon(
                      Icons.shopping_cart_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Purchase Unit'),
                    ),
                    ..._activeUnits.map(
                      (UnitOfMeasure unit) {
                        return DropdownMenuItem<String?>(
                          value: unit.code,
                          child: Text(
                            '${unit.code} | ${unit.name}',
                          ),
                        );
                      },
                    ),
                  ],
                  validator: _validatePurchaseUnit,
                  onChanged: _saving
                      ? null
                      : (String? value) {
                          setState(() {
                            _purchaseUnitCode = value;
                            _dirty = true;
                          });
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _usageUnitCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Usage Unit *',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  items: _activeUnits.map(
                    (UnitOfMeasure unit) {
                      return DropdownMenuItem<String>(
                        value: unit.code,
                        child: Text(
                          '${unit.code} | ${unit.name}',
                        ),
                      );
                    },
                  ).toList(growable: false),
                  validator: _validateUsageUnit,
                  onChanged: _saving
                      ? null
                      : (String? value) {
                          setState(() {
                            _usageUnitCode = value;
                            _dirty = true;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _factorController,
                  enabled: !_saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Conversion Factor *',
                    helperText: _conversionHelperText(),
                    prefixIcon: const Icon(
                      Icons.calculate_outlined,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    return _validatePositiveNumber(
                      value,
                      'Conversion Factor',
                    );
                  },
                  onChanged: (_) {
                    _markDirty();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  enabled: !_saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Latest Purchase Cost *',
                    prefixText: '₱ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    return _validateNonNegativeNumber(
                      value,
                      'Latest Purchase Cost',
                    );
                  },
                  onChanged: (_) {
                    _markDirty();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                _buildCostPreview(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reorderController,
                  enabled: !_saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Reorder Level *',
                    prefixIcon: Icon(
                      Icons.notification_add_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    return _validateNonNegativeNumber(
                      value,
                      'Reorder Level',
                    );
                  },
                  onChanged: (_) {
                    _markDirty();
                    _formKey.currentState?.validate();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _parController,
                  enabled: !_saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Par Level',
                    prefixIcon: Icon(Icons.inventory_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateParLevel,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  enabled: !_saving,
                  maxLength: 500,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateNotes,
                  onChanged: (_) => _markDirty(),
                ),
                SwitchListTile.adaptive(
                  value: _active,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Ingredient'),
                  subtitle: const Text(
                    'Inactive Ingredients remain '
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : _handleBackNavigation,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveIngredient,
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
                                ? 'Update Ingredient'
                                : 'Save Ingredient',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
