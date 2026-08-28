import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchen_sync/data/repositories/supplier_repository.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:uuid/uuid.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;
  final String? currentUserId;

  const SupplierFormScreen({
    super.key,
    this.supplier,
    this.currentUserId,
  });

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  static const Color _green = Color(0xFF2E6B4F);
  static const Color _paper = Color(0xFFF8F6F1);
  static const Color _ink = Color(0xFF183027);
  static const Color _muted = Color(0xFF64756B);
  static const Color _line = Color(0xFFDBE5DD);
  static const Color _danger = Color(0xFFA34036);

  static const List<String> _paymentTermOptions = <String>[
    'CASH',
    'COD',
    'NET 7',
    'NET 15',
    'NET 30',
    'NET 45',
    'NET 60',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final SupplierRepository _repository = const SupplierRepository();

  final TextEditingController _codeController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _contactController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _taxIdController = TextEditingController();

  final TextEditingController _leadTimeController =
      TextEditingController(text: '0');

  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _contactFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _taxIdFocusNode = FocusNode();
  final FocusNode _leadTimeFocusNode = FocusNode();

  String? _paymentTerms;
  bool _active = true;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.supplier != null;

  String get _screenTitle => _isEditing ? 'Edit Supplier' : 'Add Supplier';

  String get _saveLabel => _isEditing ? 'Save Changes' : 'Save Supplier';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final Supplier? supplier = widget.supplier;

    if (supplier == null) {
      _active = true;
      _leadTimeController.text = '0';
      return;
    }

    _codeController.text = supplier.supplierCode;
    _nameController.text = supplier.supplierName;
    _contactController.text = supplier.contactPerson ?? '';
    _phoneController.text = supplier.phone ?? '';
    _emailController.text = supplier.email ?? '';
    _addressController.text = supplier.address ?? '';
    _taxIdController.text = supplier.taxId ?? '';
    _leadTimeController.text = supplier.leadTimeDays.toString();

    final String? existingTerms = _optionalValue(supplier.paymentTerms);

    if (existingTerms != null && _paymentTermOptions.contains(existingTerms)) {
      _paymentTerms = existingTerms;
    }

    _active = supplier.active;
  }

  void _markDirty() {
    if (_dirty) {
      return;
    }

    setState(() {
      _dirty = true;
    });
  }

  String? _validateSupplierCode(String? value) {
    final String code = value?.trim().toUpperCase() ?? '';

    if (code.isEmpty) {
      return 'Supplier code is required.';
    }

    if (code.length > 30) {
      return 'Supplier code must not exceed 30 characters.';
    }

    if (code.contains(' ')) {
      return 'Supplier code cannot contain spaces.';
    }

    final RegExp validCode = RegExp(r'^[A-Z0-9_]+$');

    if (!validCode.hasMatch(code)) {
      return 'Use letters, numbers, and underscores only.';
    }

    return null;
  }

  String? _validateSupplierName(String? value) {
    final String name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Supplier name is required.';
    }

    if (name.length > 120) {
      return 'Supplier name must not exceed 120 characters.';
    }

    return null;
  }

  String? _validateContactPerson(String? value) {
    final String contact = value?.trim() ?? '';

    if (contact.length > 100) {
      return 'Contact person must not exceed 100 characters.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final String phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return null;
    }

    if (phone.length > 30) {
      return 'Phone number must not exceed 30 characters.';
    }

    final RegExp validPhone = RegExp(r'^[0-9+() -]+$');

    if (!validPhone.hasMatch(phone)) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    if (email.length > 120) {
      return 'Email address must not exceed 120 characters.';
    }

    final RegExp validEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!validEmail.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final String address = value?.trim() ?? '';

    if (address.length > 300) {
      return 'Address must not exceed 300 characters.';
    }

    return null;
  }

  String? _validateTaxId(String? value) {
    final String taxId = value?.trim() ?? '';

    if (taxId.length > 50) {
      return 'Tax ID must not exceed 50 characters.';
    }

    return null;
  }

  String? _validateLeadTime(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Lead time is required.';
    }

    final int? days = int.tryParse(text);

    if (days == null) {
      return 'Enter a valid number of days.';
    }

    if (days < 0) {
      return 'Lead time cannot be negative.';
    }

    if (days > 3650) {
      return 'Lead time must not exceed 3,650 days.';
    }

    return null;
  }

  String? _optionalValue(String? value) {
    final String normalized = value?.trim() ?? '';

    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please correct the highlighted fields before saving.',
            ),
          ),
        );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final DateTime now = DateTime.now().toUtc();
      final Supplier? original = widget.supplier;

      final Supplier supplier = Supplier(
        id: original?.id ?? const Uuid().v4(),
        supplierCode: _codeController.text.trim().toUpperCase(),
        supplierName: _nameController.text.trim(),
        contactPerson: _optionalValue(
          _contactController.text,
        ),
        phone: _optionalValue(
          _phoneController.text,
        ),
        email: _optionalValue(
          _emailController.text,
        ),
        address: _optionalValue(
          _addressController.text,
        ),
        taxId: _optionalValue(
          _taxIdController.text,
        ),
        paymentTerms: _paymentTerms,
        leadTimeDays: int.parse(
          _leadTimeController.text.trim(),
        ),
        active: _active,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
        createdBy: original?.createdBy ?? widget.currentUserId,
        updatedBy: widget.currentUserId,
        syncStatus: MasterSyncStatus.pending,
        serverVersion: original?.serverVersion ?? 0,
        deletedAt: original?.deletedAt,
      );

      supplier.validate();

      await _repository.saveSupplier(supplier);

      if (!mounted) {
        return;
      }

      _dirty = false;

      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      _showSaveError(error.message);
    } on FormatException catch (error) {
      _showSaveError(error.message);
    } catch (_) {
      _showSaveError(
        'Unable to save the supplier. Please try again.',
      );
    }
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
        ),
      );
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
      builder: (BuildContext dialogContext) {
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
            'The changes made to this supplier have not been saved.',
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
                backgroundColor: _danger,
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

  Future<void> _cancel() async {
    await _handleBackNavigation();
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

        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _saving ? null : _handleBackNavigation,
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: Text(_screenTitle),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool wide = constraints.maxWidth >= 760;

              return Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.all(
                          wide ? 28 : 16,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 960,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 20),
                                _SupplierFormCard(
                                  child: wide
                                      ? _buildTabletFields()
                                      : _buildPhoneFields(),
                                ),
                                const SizedBox(height: 24),
                              ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _screenTitle,
          style: const TextStyle(
            color: _ink,
            fontSize: 27,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _isEditing
              ? 'Update supplier information, operational terms, '
                  'and availability.'
              : 'Create a supplier for purchasing, receiving, '
                  'products, and ingredients.',
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
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
        _buildContactField(),
        const SizedBox(height: 16),
        _buildPhoneField(),
        const SizedBox(height: 16),
        _buildEmailField(),
        const SizedBox(height: 16),
        _buildAddressField(),
        const SizedBox(height: 16),
        _buildTaxIdField(),
        const SizedBox(height: 16),
        _buildPaymentTermsField(),
        const SizedBox(height: 16),
        _buildLeadTimeField(),
        const Divider(height: 32),
        _buildActiveSwitch(),
      ],
    );
  }

  Widget _buildTabletFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCodeField()),
            const SizedBox(width: 18),
            Expanded(child: _buildContactField()),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildNameField()),
            const SizedBox(width: 18),
            Expanded(child: _buildPhoneField()),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEmailField()),
            const SizedBox(width: 18),
            Expanded(child: _buildTaxIdField()),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAddressField()),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  _buildPaymentTermsField(),
                  const SizedBox(height: 18),
                  _buildLeadTimeField(),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
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
      maxLength: 30,
      inputFormatters: [
        const _UpperCaseTextFormatter(),
        FilteringTextInputFormatter.allow(
          RegExp(r'[A-Za-z0-9_]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: 'Supplier Code *',
        hintText: 'Example: SUP001',
        helperText: _isEditing
            ? 'Supplier code is locked to protect existing references.'
            : 'Letters, numbers, and underscores only.',
        prefixIcon: const Icon(Icons.tag),
        border: const OutlineInputBorder(),
      ),
      validator: _validateSupplierCode,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      enabled: !_saving,
      maxLength: 120,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Supplier Name *',
        hintText: 'Example: Cebu Food Supply',
        prefixIcon: Icon(Icons.business_outlined),
        border: OutlineInputBorder(),
      ),
      validator: _validateSupplierName,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildContactField() {
    return TextFormField(
      controller: _contactController,
      focusNode: _contactFocusNode,
      enabled: !_saving,
      maxLength: 100,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Contact Person',
        hintText: 'Primary supplier contact',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      validator: _validateContactPerson,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocusNode,
      enabled: !_saving,
      maxLength: 30,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[0-9+() -]'),
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Phone',
        hintText: 'Example: 09171234567',
        prefixIcon: Icon(Icons.phone_outlined),
        border: OutlineInputBorder(),
      ),
      validator: _validatePhone,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      enabled: !_saving,
      maxLength: 120,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Example: orders@supplier.com',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      validator: _validateEmail,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      focusNode: _addressFocusNode,
      enabled: !_saving,
      minLines: 3,
      maxLines: 5,
      maxLength: 300,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Address',
        hintText: 'Supplier business address',
        prefixIcon: Icon(Icons.location_on_outlined),
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
      validator: _validateAddress,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildTaxIdField() {
    return TextFormField(
      controller: _taxIdController,
      focusNode: _taxIdFocusNode,
      enabled: !_saving,
      maxLength: 50,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Tax ID or TIN',
        hintText: 'Supplier tax identification number',
        prefixIcon: Icon(Icons.receipt_long_outlined),
        border: OutlineInputBorder(),
      ),
      validator: _validateTaxId,
      onChanged: (_) => _markDirty(),
    );
  }

  Widget _buildPaymentTermsField() {
    return DropdownButtonFormField<String?>(
      initialValue: _paymentTerms,
      decoration: const InputDecoration(
        labelText: 'Payment Terms',
        prefixIcon: Icon(Icons.payments_outlined),
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('No payment terms'),
        ),
        ..._paymentTermOptions.map(
          (String value) {
            return DropdownMenuItem<String?>(
              value: value,
              child: Text(
                _paymentTermLabel(value),
              ),
            );
          },
        ),
      ],
      onChanged: _saving
          ? null
          : (String? value) {
              setState(() {
                _paymentTerms = value;
                _dirty = true;
              });
            },
    );
  }

  Widget _buildLeadTimeField() {
    return TextFormField(
      controller: _leadTimeController,
      focusNode: _leadTimeFocusNode,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: const InputDecoration(
        labelText: 'Lead Time in Days *',
        hintText: 'Example: 3',
        prefixIcon: Icon(Icons.schedule_outlined),
        suffixText: 'days',
        helperText: 'Expected number of days from order to delivery.',
        border: OutlineInputBorder(),
      ),
      validator: _validateLeadTime,
      onChanged: (_) => _markDirty(),
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
        'Inactive suppliers remain in historical records '
        'but cannot be selected for new purchasing, receiving, '
        'product, or ingredient records.',
      ),
      onChanged: _saving
          ? null
          : (bool value) {
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
              maxWidth: 960,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
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
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    label: Text(
                      _saving ? 'Saving...' : _saveLabel,
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

  static String _paymentTermLabel(String value) {
    return switch (value) {
      'CASH' => 'Cash',
      'COD' => 'Cash on Delivery',
      'NET 7' => 'Net 7 Days',
      'NET 15' => 'Net 15 Days',
      'NET 30' => 'Net 30 Days',
      'NET 45' => 'Net 45 Days',
      'NET 60' => 'Net 60 Days',
      _ => value,
    };
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _leadTimeController.dispose();

    _codeFocusNode.dispose();
    _nameFocusNode.dispose();
    _contactFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _addressFocusNode.dispose();
    _taxIdFocusNode.dispose();
    _leadTimeFocusNode.dispose();

    super.dispose();
  }
}

class _SupplierFormCard extends StatelessWidget {
  final Widget child;

  const _SupplierFormCard({
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
