import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/product_repository.dart';
import 'package:kitchen_sync/data/repositories/recipe_repository.dart';
import 'package:kitchen_sync/domain/models/product.dart';
import 'package:kitchen_sync/domain/models/recipe.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() {
    return _ProductFormScreenState();
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ProductRepository _productRepository = const ProductRepository();

  final RecipeRepository _recipeRepository = const RecipeRepository();

  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _departmentNameController;
  late final TextEditingController _classCodeController;
  late final TextEditingController _classNameController;
  late final TextEditingController _subclassController;
  late final TextEditingController _subclassNameController;
  late final TextEditingController _supplierIdController;
  late final TextEditingController _supplierNameController;
  late final TextEditingController _brandController;
  late final TextEditingController _usageController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  late final TextEditingController _retailController;
  late final TextEditingController _vatController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _imagePublicIdController;

  ProductInventoryMode _inventoryMode = ProductInventoryMode.direct;

  ProductCostingMethod _costingMethod = ProductCostingMethod.manual;

  String? _recipeId;

  List<Recipe> _activeRecipes = <Recipe>[];

  bool _loadingReferences = true;
  bool _saving = false;
  String? _referenceError;

  bool get _isEditing {
    return widget.product != null;
  }

  @override
  void initState() {
    super.initState();

    final Product? product = widget.product;

    _skuController = TextEditingController(
      text: product?.sku ?? '',
    );

    _barcodeController = TextEditingController(
      text: product?.barcode ?? '',
    );

    _nameController = TextEditingController(
      text: product?.productName ?? '',
    );

    _departmentController = TextEditingController(
      text: product?.department ?? '',
    );

    _departmentNameController = TextEditingController(
      text: product?.departmentName ?? '',
    );

    _classCodeController = TextEditingController(
      text: product?.classCode ?? '',
    );

    _classNameController = TextEditingController(
      text: product?.className ?? '',
    );

    _subclassController = TextEditingController(
      text: product?.subclass ?? '',
    );

    _subclassNameController = TextEditingController(
      text: product?.subclassName ?? '',
    );

    _supplierIdController = TextEditingController(
      text: product?.supplierId ?? '',
    );

    _supplierNameController = TextEditingController(
      text: product?.supplierName ?? '',
    );

    _brandController = TextEditingController(
      text: product?.brandName ?? '',
    );

    _usageController = TextEditingController(
      text: product?.productUsage ?? '',
    );

    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );

    _costController = TextEditingController(
      text: (product?.cost ?? 0).toStringAsFixed(2),
    );

    _retailController = TextEditingController(
      text: (product?.retailPrice ?? 0).toStringAsFixed(2),
    );

    _vatController = TextEditingController(
      text: (product?.vat ?? 0).toStringAsFixed(2),
    );

    _imageUrlController = TextEditingController(
      text: product?.imageUrl ?? '',
    );

    _imagePublicIdController = TextEditingController(
      text: product?.imagePublicId ?? '',
    );

    _inventoryMode = product?.inventoryMode ?? ProductInventoryMode.direct;

    _costingMethod = product?.costingMethod ?? ProductCostingMethod.manual;

    _recipeId = product?.recipeId;

    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (mounted) {
      setState(() {
        _loadingReferences = true;
        _referenceError = null;
      });
    }

    try {
      final List<Recipe> recipes = await _recipeRepository.getRecipes();

      final List<Recipe> activeRecipes = recipes.where(
        (Recipe recipe) {
          return recipe.active && !recipe.isDeleted;
        },
      ).toList(growable: false);

      activeRecipes.sort(
        (Recipe first, Recipe second) {
          return first.recipeName.toLowerCase().compareTo(
                second.recipeName.toLowerCase(),
              );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeRecipes = activeRecipes;
        _loadingReferences = false;

        if (_recipeId != null &&
            !_activeRecipes.any(
              (Recipe recipe) {
                return recipe.id == _recipeId;
              },
            )) {
          _recipeId = null;
        }
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load Product references: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingReferences = false;
        _referenceError = 'Unable to load active Recipes.';
      });
    }
  }

  String? _requiredText(
    String? value,
    String field,
  ) {
    if ((value ?? '').trim().isEmpty) {
      return '$field is required.';
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
      return '$field must be zero or greater.';
    }

    return null;
  }

  String? _optionalText(
    TextEditingController controller,
  ) {
    final String value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  String _inventoryModeLabel(
    ProductInventoryMode mode,
  ) {
    switch (mode) {
      case ProductInventoryMode.direct:
        return 'DIRECT';
      case ProductInventoryMode.recipe:
        return 'RECIPE';
      case ProductInventoryMode.none:
        return 'NONE';
    }
  }

  String _costingMethodLabel(
    ProductCostingMethod method,
  ) {
    switch (method) {
      case ProductCostingMethod.manual:
        return 'MANUAL';
      case ProductCostingMethod.ingredient:
        return 'INGREDIENT';
      case ProductCostingMethod.hybrid:
        return 'HYBRID';
    }
  }

  void _changeInventoryMode(
    ProductInventoryMode? mode,
  ) {
    if (mode == null) {
      return;
    }

    setState(() {
      _inventoryMode = mode;

      if (mode != ProductInventoryMode.recipe) {
        _recipeId = null;

        if (_costingMethod == ProductCostingMethod.ingredient) {
          _costingMethod = ProductCostingMethod.manual;
        }
      }
    });
  }

  Future<void> _saveProduct() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_inventoryMode == ProductInventoryMode.recipe && _recipeId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Select an active Recipe for '
              'RECIPE Inventory Mode.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final DateTime now = DateTime.now().toUtc();

      final Product product = Product(
        id: widget.product?.id ??
            'product-'
                '${DateTime.now().microsecondsSinceEpoch}',
        sku: _skuController.text,
        barcode: _optionalText(
          _barcodeController,
        ),
        productName: _nameController.text,
        department: _optionalText(
          _departmentController,
        ),
        departmentName: _optionalText(
          _departmentNameController,
        ),
        classCode: _optionalText(
          _classCodeController,
        ),
        className: _optionalText(
          _classNameController,
        ),
        subclass: _optionalText(
          _subclassController,
        ),
        subclassName: _optionalText(
          _subclassNameController,
        ),
        supplierId: _optionalText(
          _supplierIdController,
        ),
        supplierName: _optionalText(
          _supplierNameController,
        ),
        brandName: _optionalText(
          _brandController,
        ),
        productUsage: _optionalText(
          _usageController,
        ),
        description: _optionalText(
          _descriptionController,
        ),
        cost: double.parse(
          _costController.text.trim(),
        ),
        retailPrice: double.parse(
          _retailController.text.trim(),
        ),
        vat: double.parse(
          _vatController.text.trim(),
        ),
        active: widget.product?.active ?? true,
        inventoryMode: _inventoryMode,
        costingMethod: _costingMethod,
        recipeId:
            _inventoryMode == ProductInventoryMode.recipe ? _recipeId : null,
        imageUrl: _optionalText(
          _imageUrlController,
        ),
        imagePublicId: _optionalText(
          _imagePublicIdController,
        ),
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      await _productRepository.saveProduct(
        product,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to save Product: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.toString(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResponsivePair(
    Widget first,
    Widget second,
  ) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        if (constraints.maxWidth >= 680) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 14),
              Expanded(child: second),
            ],
          );
        }

        return Column(
          children: [
            first,
            const SizedBox(height: 14),
            second,
          ],
        );
      },
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
                onPressed: _loadRecipes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _isEditing ? 'Edit Product' : 'Add Product',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Configure selling, costing, and '
            'inventory behavior for this Product.',
          ),
          const SizedBox(height: 24),
          _buildResponsivePair(
            _buildTextField(
              controller: _skuController,
              label: 'SKU *',
              icon: Icons.qr_code_2,
              validator: (String? value) {
                return _requiredText(
                  value,
                  'SKU',
                );
              },
            ),
            _buildTextField(
              controller: _barcodeController,
              label: 'Barcode',
              icon: Icons.barcode_reader,
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _nameController,
            label: 'Product Name *',
            icon: Icons.inventory_2_outlined,
            validator: (String? value) {
              return _requiredText(
                value,
                'Product Name',
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'Selling and Costing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _costController,
              label: 'Cost *',
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (String? value) {
                return _nonNegativeNumber(
                  value,
                  'Cost',
                );
              },
            ),
            _buildTextField(
              controller: _retailController,
              label: 'Retail Price *',
              icon: Icons.sell_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (String? value) {
                return _nonNegativeNumber(
                  value,
                  'Retail Price',
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _vatController,
            label: 'VAT',
            icon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (String? value) {
              return _nonNegativeNumber(
                value,
                'VAT',
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'Inventory Configuration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            DropdownButtonFormField<ProductInventoryMode>(
              initialValue: _inventoryMode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Inventory Mode *',
                prefixIcon: Icon(
                  Icons.warehouse_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              items: ProductInventoryMode.values.map(
                (ProductInventoryMode mode) {
                  return DropdownMenuItem<ProductInventoryMode>(
                    value: mode,
                    child: Text(
                      _inventoryModeLabel(mode),
                    ),
                  );
                },
              ).toList(growable: false),
              onChanged: _saving ? null : _changeInventoryMode,
            ),
            DropdownButtonFormField<ProductCostingMethod>(
              initialValue: _costingMethod,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Costing Method *',
                prefixIcon: Icon(
                  Icons.calculate_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              items: ProductCostingMethod.values.where(
                (ProductCostingMethod method) {
                  if (_inventoryMode == ProductInventoryMode.recipe) {
                    return true;
                  }

                  return method != ProductCostingMethod.ingredient;
                },
              ).map(
                (ProductCostingMethod method) {
                  return DropdownMenuItem<ProductCostingMethod>(
                    value: method,
                    child: Text(
                      _costingMethodLabel(method),
                    ),
                  );
                },
              ).toList(growable: false),
              onChanged: _saving
                  ? null
                  : (
                      ProductCostingMethod? method,
                    ) {
                      if (method == null) {
                        return;
                      }

                      setState(() {
                        _costingMethod = method;
                      });
                    },
            ),
          ),
          if (_inventoryMode == ProductInventoryMode.recipe) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _recipeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Recipe *',
                prefixIcon: Icon(
                  Icons.menu_book_outlined,
                ),
                border: OutlineInputBorder(),
                helperText: 'Ingredient quantities will be '
                    'based on this Recipe.',
              ),
              items: _activeRecipes.map(
                (Recipe recipe) {
                  return DropdownMenuItem<String>(
                    value: recipe.id,
                    child: Text(
                      '${recipe.recipeCode} • '
                      '${recipe.recipeName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList(growable: false),
              validator: (String? value) {
                if (_inventoryMode == ProductInventoryMode.recipe &&
                    (value ?? '').trim().isEmpty) {
                  return 'Recipe is required.';
                }

                return null;
              },
              onChanged: _saving
                  ? null
                  : (String? value) {
                      setState(() {
                        _recipeId = value;
                      });
                    },
            ),
            if (_activeRecipes.isEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'No active Recipes are available. '
                'Create or activate a Recipe first.',
                style: TextStyle(
                  color: Color(0xFFB42318),
                ),
              ),
            ],
          ],
          const SizedBox(height: 22),
          Text(
            'Classification',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _departmentController,
              label: 'Department Code',
            ),
            _buildTextField(
              controller: _departmentNameController,
              label: 'Department Name',
            ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _classCodeController,
              label: 'Class Code',
            ),
            _buildTextField(
              controller: _classNameController,
              label: 'Class Name',
            ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _subclassController,
              label: 'Subclass Code',
            ),
            _buildTextField(
              controller: _subclassNameController,
              label: 'Subclass Name',
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Additional Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _supplierIdController,
              label: 'Supplier ID',
            ),
            _buildTextField(
              controller: _supplierNameController,
              label: 'Supplier Name',
            ),
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _brandController,
              label: 'Brand',
            ),
            _buildTextField(
              controller: _usageController,
              label: 'Product Usage',
            ),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _buildResponsivePair(
            _buildTextField(
              controller: _imageUrlController,
              label: 'Image URL',
            ),
            _buildTextField(
              controller: _imagePublicIdController,
              label: 'Image Public ID',
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              final Widget cancelButton = OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancel'),
              );

              final Widget saveButton = FilledButton.icon(
                onPressed: _saving ? null : _saveProduct,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : _isEditing
                          ? 'Update Product'
                          : 'Save Product',
                ),
              );

              if (constraints.maxWidth < 480) {
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
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _departmentNameController.dispose();
    _classCodeController.dispose();
    _classNameController.dispose();
    _subclassController.dispose();
    _subclassNameController.dispose();
    _supplierIdController.dispose();
    _supplierNameController.dispose();
    _brandController.dispose();
    _usageController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _retailController.dispose();
    _vatController.dispose();
    _imageUrlController.dispose();
    _imagePublicIdController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }
}
