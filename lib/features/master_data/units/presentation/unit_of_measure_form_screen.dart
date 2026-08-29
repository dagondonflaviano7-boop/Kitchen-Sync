import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchen_sync/data/repositories/unit_of_measure_repository.dart';
import 'package:kitchen_sync/data/services/master_data_auto_sync.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:uuid/uuid.dart';

class UnitOfMeasureFormScreen extends StatefulWidget {
  final UnitOfMeasure? unit;

  const UnitOfMeasureFormScreen({
    super.key,
    this.unit,
  });

  @override
  State<UnitOfMeasureFormScreen> createState() =>
      _UnitOfMeasureFormScreenState();
}

class _UnitOfMeasureFormScreenState extends State<UnitOfMeasureFormScreen> {
  static const Color _green = Color(0xFF2E6B4F);
  static const Color _paper = Color(0xFFF8F6F1);
  static const Color _ink = Color(0xFF183027);
  static const Color _muted = Color(0xFF64756B);
  static const Color _line = Color(0xFFDBE5DD);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final UnitOfMeasureRepository _repository = const UnitOfMeasureRepository();

  final TextEditingController _codeController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _factorController =
      TextEditingController(text: '1');

  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _factorFocusNode = FocusNode();

  List<UnitOfMeasure> _availableUnits = <UnitOfMeasure>[];

  UnitType _unitType = UnitType.count;
  String? _baseUnitCode;
  bool _allowDecimal = false;
  bool _active = true;
  bool _saving = false;
  bool _loadingBaseUnits = true;
  bool _dirty = false;
  bool _decimalManuallyChanged = false;

  String? _loadingError;

  bool get _isEditing => widget.unit != null;

  bool get _hasBaseUnit =>
      _baseUnitCode != null && _baseUnitCode!.trim().isNotEmpty;

  List<UnitOfMeasure> get _compatibleBaseUnits {
    return _availableUnits.where((candidate) {
      final bool compatibleType = candidate.unitType == _unitType;

      final bool notCurrentUnit = candidate.code.toUpperCase() !=
          _codeController.text.trim().toUpperCase();

      final bool typeSupportsBase =
          _unitType == UnitType.weight || _unitType == UnitType.volume;

      return candidate.active &&
          compatibleType &&
          notCurrentUnit &&
          typeSupportsBase;
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadBaseUnits();
  }

  void _initializeForm() {
    final UnitOfMeasure? unit = widget.unit;

    if (unit == null) {
      _unitType = UnitType.count;
      _allowDecimal = false;
      _active = true;
      _factorController.text = '1';
      return;
    }

    _codeController.text = unit.code;
    _nameController.text = unit.name;
    _factorController.text = _formatNumber(unit.conversionFactor);

    _unitType = unit.unitType;
    _baseUnitCode = unit.baseUnitCode;
    _allowDecimal = unit.allowDecimal;
    _active = unit.active;
  }

  Future<void> _loadBaseUnits() async {
    try {
      await _repository.seedStandardUnits();

      final List<UnitOfMeasure> units = await _repository.getUnits(
        includeInactive: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availableUnits = units;
        _loadingBaseUnits = false;
        _loadingError = null;

        if (_baseUnitCode != null &&
            !_compatibleBaseUnits.any(
              (unit) => unit.code == _baseUnitCode,
            )) {
          _baseUnitCode = null;
          _factorController.text = '1';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingBaseUnits = false;
        _loadingError = error.toString();
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

  void _handleUnitTypeChanged(
    UnitType? value,
  ) {
    if (value == null || value == _unitType) {
      return;
    }

    setState(() {
      _unitType = value;
      _baseUnitCode = null;
      _factorController.text = '1';
      _dirty = true;

      if (!_decimalManuallyChanged) {
        _allowDecimal = value == UnitType.weight || value == UnitType.volume;
      }
    });
  }

  void _handleBaseUnitChanged(
    String? value,
  ) {
    setState(() {
      _baseUnitCode = value;
      _dirty = true;

      if (value == null) {
        _factorController.text = '1';
      }
    });
  }

  String? _validateCode(String? value) {
    final String code = value?.trim().toUpperCase() ?? '';

    if (code.isEmpty) {
      return 'Unit code is required.';
    }

    if (code.length > 20) {
      return 'Unit code must not exceed 20 characters.';
    }

    if (code.contains(' ')) {
      return 'Unit code cannot contain spaces.';
    }

    final RegExp validCode = RegExp(r'^[A-Z0-9_]+$');

    if (!validCode.hasMatch(code)) {
      return 'Use letters, numbers, and underscores only.';
    }

    return null;
  }

  String? _validateName(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Unit name is required.';
    }

    if (name.length > 60) {
      return 'Unit name must not exceed 60 characters.';
    }

    return null;
  }

  String? _validateFactor(String? value) {
    if (!_hasBaseUnit) {
      return null;
    }

    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Conversion factor is required when a base unit is selected.';
    }

    final double? factor = double.tryParse(text);

    if (factor == null) {
      return 'Enter a valid conversion factor.';
    }

    if (factor <= 0) {
      return 'Conversion factor must be greater than zero.';
    }

    return null;
  }

  String? _validateBaseUnit() {
    final String? baseCode = _baseUnitCode;

    if (baseCode == null) {
      return null;
    }

    final String currentCode = _codeController.text.trim().toUpperCase();

    if (baseCode.toUpperCase() == currentCode) {
      return 'A unit cannot use itself as its base unit.';
    }

    final UnitOfMeasure? baseUnit = _findUnitByCode(baseCode);

    if (baseUnit == null || !baseUnit.active) {
      return 'Select an active base unit.';
    }

    if (baseUnit.unitType != _unitType) {
      return 'The base unit must use the same measurement type.';
    }

    if (_unitType == UnitType.packaging) {
      return 'Packaging conversions must be configured per product.';
    }

    if (_unitType == UnitType.count) {
      return 'Count units do not use a universal base conversion.';
    }

    return null;
  }

  UnitOfMeasure? _findUnitByCode(String code) {
    for (final UnitOfMeasure unit in _availableUnits) {
      if (unit.code.toUpperCase() == code.toUpperCase()) {
        return unit;
      }
    }

    return null;
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving) {
      return !_saving;
    }

    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'The changes made to this unit have not been saved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return discard ?? false;
  }

  Future<void> _cancel() async {
    final bool canLeave = await _confirmDiscard();

    if (!canLeave || !mounted) {
      return;
    }

    Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool fieldsValid = _formKey.currentState?.validate() ?? false;

    final String? baseUnitError = _validateBaseUnit();

    if (!fieldsValid || baseUnitError != null) {
      if (baseUnitError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(baseUnitError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final DateTime now = DateTime.now().toUtc();
      final UnitOfMeasure? original = widget.unit;

      final String code = _codeController.text.trim().toUpperCase();

      final double factor =
          _hasBaseUnit ? double.parse(_factorController.text.trim()) : 1;

      final UnitOfMeasure unit = UnitOfMeasure(
        id: original?.id ?? const Uuid().v4(),
        code: code,
        name: _nameController.text.trim(),
        unitType: _unitType,
        baseUnitCode: _baseUnitCode,
        conversionFactor: factor,
        allowDecimal: _allowDecimal,
        active: _active,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
        syncStatus: MasterSyncStatus.pending,
        serverVersion: original?.serverVersion ?? 0,
        deletedAt: original?.deletedAt,
      );

      unit.validate();

      await _repository.saveUnit(unit);

      unawaited(
        MasterDataAutoSync.instance.trigger(
          reason: MasterDataAutoSyncReason.unitSaved,
        ),
      );

      if (!mounted) {
        return;
      }

      _dirty = false;

      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      setState(() {
        _saving = false;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      setState(() {
        _saving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save the unit. Please try again.',
          ),
        ),
      );

      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (
        bool didPop,
        Object? result,
      ) async {
        if (didPop) {
          return;
        }

        await _cancel();
      },
      child: Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Unit' : 'Add Unit',
          ),
        ),
        body: SafeArea(
          child: _loadingBaseUnits
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _loadingError != null
                  ? _buildLoadingError()
                  : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildLoadingError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load unit settings.',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadingError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loadingBaseUnits = true;
                  _loadingError = null;
                });

                _loadBaseUnits();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 720;

        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    wide ? 28 : 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 900,
                      ),
                      child: _FormCard(
                        child: wide ? _buildWideFields() : _buildPhoneFields(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildActionBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCodeField(),
        const SizedBox(height: 16),
        _buildNameField(),
        const SizedBox(height: 16),
        _buildTypeField(),
        const SizedBox(height: 16),
        _buildBaseUnitField(),
        const SizedBox(height: 16),
        _buildFactorField(),
        const SizedBox(height: 10),
        _buildDecimalSwitch(),
        const Divider(height: 28),
        _buildActiveSwitch(),
      ],
    );
  }

  Widget _buildWideFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCodeField()),
            const SizedBox(width: 18),
            Expanded(child: _buildTypeField()),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildNameField()),
            const SizedBox(width: 18),
            Expanded(child: _buildBaseUnitField()),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDecimalSwitch()),
            const SizedBox(width: 18),
            Expanded(child: _buildFactorField()),
          ],
        ),
        const Divider(height: 30),
        _buildActiveSwitch(),
      ],
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      focusNode: _codeFocusNode,
      enabled: !_isEditing && !_saving,
      textCapitalization: TextCapitalization.characters,
      maxLength: 20,
      inputFormatters: [
        const _UpperCaseTextFormatter(),
        FilteringTextInputFormatter.allow(
          RegExp(r'[A-Za-z0-9_]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: 'Unit Code *',
        hintText: 'Example: PCS',
        helperText: _isEditing
            ? 'Unit code is locked to protect existing references.'
            : 'Letters, numbers, and underscores only.',
        prefixIcon: const Icon(Icons.tag),
        border: const OutlineInputBorder(),
      ),
      validator: _validateCode,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      enabled: !_saving,
      maxLength: 60,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Unit Name *',
        hintText: 'Example: Pieces',
        prefixIcon: Icon(Icons.label_outline),
        border: OutlineInputBorder(),
      ),
      validator: _validateName,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildTypeField() {
    return DropdownButtonFormField<UnitType>(
      initialValue: _unitType,
      decoration: const InputDecoration(
        labelText: 'Unit Type *',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      items: UnitType.values.map((type) {
        return DropdownMenuItem<UnitType>(
          value: type,
          child: Text(
            _unitTypeLabel(type),
          ),
        );
      }).toList(growable: false),
      onChanged: _saving ? null : _handleUnitTypeChanged,
    );
  }

  Widget _buildBaseUnitField() {
    final List<UnitOfMeasure> compatible = _compatibleBaseUnits;

    final bool enabled = !_saving &&
        (_unitType == UnitType.weight || _unitType == UnitType.volume);

    return DropdownButtonFormField<String?>(
      initialValue: _baseUnitCode,
      decoration: InputDecoration(
        labelText: 'Base Unit',
        helperText: enabled
            ? 'Select a compatible physical base unit.'
            : 'Not used for Count or Packaging units.',
        prefixIcon: const Icon(Icons.compare_arrows),
        border: const OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('No base unit'),
        ),
        ...compatible.map(
          (unit) => DropdownMenuItem<String?>(
            value: unit.code,
            child: Text(
              '${unit.code} — ${unit.name}',
            ),
          ),
        ),
      ],
      onChanged: enabled ? _handleBaseUnitChanged : null,
    );
  }

  Widget _buildFactorField() {
    return TextFormField(
      controller: _factorController,
      focusNode: _factorFocusNode,
      enabled: _hasBaseUnit && !_saving,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d*'),
        ),
      ],
      decoration: InputDecoration(
        labelText: 'Conversion Factor',
        hintText: 'Example: 1000',
        helperText: _hasBaseUnit
            ? '1 ${_codeController.text.isEmpty ? 'unit' : _codeController.text} '
                '= factor × $_baseUnitCode'
            : 'Defaults to 1 when no base unit is selected.',
        prefixIcon: const Icon(Icons.calculate_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: _validateFactor,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildDecimalSwitch() {
    return SwitchListTile.adaptive(
      value: _allowDecimal,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: _green,
      title: const Text(
        'Allow Decimal Quantity',
        style: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Enable quantities such as 0.25, 1.5, or 2.75.',
      ),
      onChanged: _saving
          ? null
          : (value) {
              setState(() {
                _allowDecimal = value;
                _decimalManuallyChanged = true;
                _dirty = true;
              });
            },
    );
  }

  Widget _buildActiveSwitch() {
    return SwitchListTile.adaptive(
      value: _active,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: _green,
      title: const Text(
        'Active Status',
        style: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text(
        'Inactive units remain in historical records but cannot be assigned to new items.',
      ),
      onChanged: _saving
          ? null
          : (value) {
              setState(() {
                _active = value;
                _dirty = true;
              });
            },
    );
  }

  Widget _buildActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _line),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      minimumSize: const Size.fromHeight(52),
                    ),
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
                              ? 'Save Changes'
                              : 'Save Unit',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _unitTypeLabel(UnitType type) {
    return switch (type) {
      UnitType.count => 'Count',
      UnitType.weight => 'Weight',
      UnitType.volume => 'Volume',
      UnitType.packaging => 'Packaging',
    };
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _factorController.dispose();

    _codeFocusNode.dispose();
    _nameFocusNode.dispose();
    _factorFocusNode.dispose();

    super.dispose();
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFDBE5DD),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
