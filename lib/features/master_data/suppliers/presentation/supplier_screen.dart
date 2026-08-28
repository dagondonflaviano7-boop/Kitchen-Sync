import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/supplier_repository.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/features/master_data/suppliers/presentation/supplier_form_screen.dart';

enum SupplierStatusFilter {
  all,
  active,
  inactive,
}

class SupplierScreen extends StatefulWidget {
  final String? currentUserId;

  const SupplierScreen({
    super.key,
    this.currentUserId,
  });

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  static const Color _green = Color(0xFF2E6B4F);
  static const Color _paper = Color(0xFFF8F6F1);
  static const Color _ink = Color(0xFF183027);
  static const Color _muted = Color(0xFF64756B);
  static const Color _danger = Color(0xFFA34036);

  final SupplierRepository _repository = const SupplierRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Supplier> _suppliers = <Supplier>[];

  SupplierStatusFilter _statusFilter = SupplierStatusFilter.all;

  bool _loading = true;
  bool _changingStatus = false;
  String? _errorMessage;

  List<Supplier> get _filteredSuppliers {
    return _suppliers.where((Supplier supplier) {
      return switch (_statusFilter) {
        SupplierStatusFilter.all => true,
        SupplierStatusFilter.active => supplier.active,
        SupplierStatusFilter.inactive => !supplier.active,
      };
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<Supplier> suppliers = await _repository.searchSuppliers(
        _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _suppliers = suppliers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openSupplierForm({
    Supplier? supplier,
  }) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SupplierFormScreen(
          supplier: supplier,
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (saved != true || !mounted) {
      return;
    }

    await _loadSuppliers();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            supplier == null
                ? 'Supplier created successfully.'
                : 'Supplier updated successfully.',
          ),
        ),
      );
  }

  Future<bool> _confirmStatusChange(
    Supplier supplier,
  ) async {
    final bool activating = !supplier.active;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            activating
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: activating ? _green : _danger,
            size: 36,
          ),
          title: Text(
            activating ? 'Activate supplier?' : 'Deactivate supplier?',
          ),
          content: Text(
            activating
                ? '${supplier.supplierName} will become '
                    'available for new purchasing, receiving, '
                    'product, and ingredient records.'
                : '${supplier.supplierName} will no longer be '
                    'available for new records. Existing '
                    'historical records will remain unchanged.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: activating ? _green : _danger,
                foregroundColor: Colors.white,
              ),
              child: Text(
                activating ? 'Activate' : 'Deactivate',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _toggleActive(
    Supplier supplier,
  ) async {
    if (_changingStatus) {
      return;
    }

    final bool confirmed = await _confirmStatusChange(supplier);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _changingStatus = true;
    });

    try {
      await _repository.setSupplierActive(
        supplier.id,
        !supplier.active,
      );

      await _loadSuppliers();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              supplier.active
                  ? 'Supplier deactivated successfully.'
                  : 'Supplier activated successfully.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to update the supplier status.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _changingStatus = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final List<Supplier> visibleSuppliers = _filteredSuppliers;

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadSuppliers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openSupplierForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderAndFilters(
              visibleCount: visibleSuppliers.length,
            ),
            Expanded(
              child: _buildContent(
                visibleSuppliers,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndFilters({
    required int visibleCount,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supplier Master Data',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage supplier records, contacts, '
            'payment terms, and expected lead times.',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search code, name, contact, or phone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
            onSubmitted: (_) => _loadSuppliers(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<SupplierStatusFilter>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<SupplierStatusFilter>(
                        value: SupplierStatusFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment<SupplierStatusFilter>(
                        value: SupplierStatusFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment<SupplierStatusFilter>(
                        value: SupplierStatusFilter.inactive,
                        label: Text('Inactive'),
                      ),
                    ],
                    selected: <SupplierStatusFilter>{
                      _statusFilter,
                    },
                    onSelectionChanged: (selection) {
                      setState(() {
                        _statusFilter = selection.first;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1EC),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$visibleCount '
                  '${visibleCount == 1 ? 'supplier' : 'suppliers'}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<Supplier> suppliers,
  ) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _SupplierErrorState(
        message: _errorMessage!,
        onRetry: _loadSuppliers,
      );
    }

    if (suppliers.isEmpty) {
      return _SupplierEmptyState(
        hasSearch: _searchController.text.trim().isNotEmpty,
        onAdd: () => _openSupplierForm(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return _SupplierTable(
            suppliers: suppliers,
            onEdit: (Supplier supplier) => _openSupplierForm(
              supplier: supplier,
            ),
            onToggleActive: _toggleActive,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            88,
          ),
          itemCount: suppliers.length,
          separatorBuilder: (_, __) {
            return const SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final Supplier supplier = suppliers[index];

            return _SupplierCard(
              supplier: supplier,
              onEdit: () => _openSupplierForm(
                supplier: supplier,
              ),
              onToggleActive: () => _toggleActive(supplier),
            );
          },
        );
      },
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFDBE5DD),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F1EC),
                  foregroundColor: const Color(0xFF2E6B4F),
                  child: Text(
                    _supplierInitial(supplier),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.supplierName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF183027),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        supplier.supplierCode,
                        style: const TextStyle(
                          color: Color(0xFF64756B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _SupplierStatusChip(
                  active: supplier.active,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Supplier actions',
                  onSelected: (String value) {
                    if (value == 'edit') {
                      onEdit();
                    }

                    if (value == 'toggle') {
                      onToggleActive();
                    }
                  },
                  itemBuilder: (_) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              supplier.active
                                  ? Icons.toggle_off_outlined
                                  : Icons.toggle_on_outlined,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              supplier.active ? 'Deactivate' : 'Activate',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (_hasValue(supplier.contactPerson))
              _SupplierDetailRow(
                icon: Icons.person_outline,
                label: 'Contact',
                value: supplier.contactPerson!,
              ),
            if (_hasValue(supplier.phone))
              _SupplierDetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: supplier.phone!,
              ),
            if (_hasValue(supplier.paymentTerms))
              _SupplierDetailRow(
                icon: Icons.payments_outlined,
                label: 'Terms',
                value: supplier.paymentTerms!,
              ),
            _SupplierDetailRow(
              icon: Icons.schedule_outlined,
              label: 'Lead Time',
              value: '${supplier.leadTimeDays} '
                  '${supplier.leadTimeDays == 1 ? 'day' : 'days'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SupplierDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF64756B),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64756B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF183027),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierTable extends StatelessWidget {
  final List<Supplier> suppliers;
  final Future<void> Function(Supplier) onEdit;
  final Future<void> Function(Supplier) onToggleActive;

  const _SupplierTable({
    required this.suppliers,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFDBE5DD),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Code')),
              DataColumn(
                label: Text('Supplier Name'),
              ),
              DataColumn(label: Text('Contact')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Terms')),
              DataColumn(label: Text('Lead Time')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: suppliers.map((Supplier supplier) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(supplier.supplierCode),
                  ),
                  DataCell(
                    Text(supplier.supplierName),
                  ),
                  DataCell(
                    Text(
                      supplier.contactPerson ?? 'None',
                    ),
                  ),
                  DataCell(
                    Text(supplier.phone ?? 'None'),
                  ),
                  DataCell(
                    Text(
                      supplier.paymentTerms ?? 'None',
                    ),
                  ),
                  DataCell(
                    Text(
                      '${supplier.leadTimeDays} '
                      '${supplier.leadTimeDays == 1 ? 'day' : 'days'}',
                    ),
                  ),
                  DataCell(
                    _SupplierStatusChip(
                      active: supplier.active,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => onEdit(supplier),
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: supplier.active ? 'Deactivate' : 'Activate',
                          onPressed: () => onToggleActive(supplier),
                          icon: Icon(
                            supplier.active
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            color: supplier.active
                                ? const Color(0xFF2E6B4F)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _SupplierStatusChip extends StatelessWidget {
  final bool active;

  const _SupplierStatusChip({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        active ? const Color(0xFF2E6B4F) : const Color(0xFF7B4D48);

    final Color background =
        active ? const Color(0xFFE8F1EC) : const Color(0xFFF7E9E7);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SupplierEmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _SupplierEmptyState({
    required this.hasSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 62,
              color: Color(0xFF64756B),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No matching suppliers' : 'No suppliers yet',
              style: const TextStyle(
                color: Color(0xFF183027),
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try another supplier code, name, '
                      'contact, or phone number.'
                  : 'Add supplier records for purchasing, '
                      'receiving, products, and ingredients.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64756B),
                height: 1.5,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Supplier'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SupplierErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SupplierErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load suppliers',
              style: TextStyle(
                color: Color(0xFF183027),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64756B),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _supplierInitial(Supplier supplier) {
  final String name = supplier.supplierName.trim();

  if (name.isNotEmpty) {
    return name.substring(0, 1).toUpperCase();
  }

  final String code = supplier.supplierCode.trim();

  if (code.isNotEmpty) {
    return code.substring(0, 1).toUpperCase();
  }

  return '?';
}

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty;
}
