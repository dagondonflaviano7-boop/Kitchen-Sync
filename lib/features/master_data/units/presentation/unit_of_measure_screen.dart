import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/repositories/unit_of_measure_repository.dart';
import 'package:kitchen_sync/data/services/master_data_auto_sync.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';
import 'package:kitchen_sync/features/master_data/units/presentation/unit_of_measure_form_screen.dart';

String _formatFactor(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toString();
}

enum UnitStatusFilter {
  all,
  active,
  inactive,
}

class UnitOfMeasureScreen extends StatefulWidget {
  const UnitOfMeasureScreen({super.key});

  @override
  State<UnitOfMeasureScreen> createState() => _UnitOfMeasureScreenState();
}

class _UnitOfMeasureScreenState extends State<UnitOfMeasureScreen> {
  final UnitOfMeasureRepository _repository = const UnitOfMeasureRepository();

  final TextEditingController _searchController = TextEditingController();

  List<UnitOfMeasure> _units = <UnitOfMeasure>[];
  UnitStatusFilter _statusFilter = UnitStatusFilter.all;
  UnitType? _unitTypeFilter;

  bool _loading = true;
  bool _deleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _repository.seedStandardUnits();

      final List<UnitOfMeasure> units = await _repository.searchUnits(
        _searchController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _units = units;
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

  List<UnitOfMeasure> get _filteredUnits {
    return _units.where((unit) {
      final bool statusMatches = switch (_statusFilter) {
        UnitStatusFilter.all => true,
        UnitStatusFilter.active => unit.active,
        UnitStatusFilter.inactive => !unit.active,
      };

      final bool typeMatches =
          _unitTypeFilter == null || unit.unitType == _unitTypeFilter;

      return statusMatches && typeMatches;
    }).toList(growable: false);
  }

  Future<void> _openUnitForm({
    UnitOfMeasure? unit,
  }) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UnitOfMeasureFormScreen(
          unit: unit,
        ),
      ),
    );

    if (saved != true || !mounted) {
      return;
    }

    await _loadUnits();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unit == null
              ? 'Unit created successfully.'
              : 'Unit updated successfully.',
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteUnit(
    UnitOfMeasure unit,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
            size: 36,
          ),
          title: const Text('Delete unit?'),
          content: Text(
            '${unit.code} — ${unit.name} will be removed '
            'from normal master-data lists.\n\n'
            'Historical records will remain protected. '
            'The deletion will be marked for synchronization.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _showDeleteError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  Future<void> _deleteUnit(
    UnitOfMeasure unit,
  ) async {
    if (_deleting) {
      return;
    }

    final bool confirmed = await _confirmDeleteUnit(unit);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await _repository.deleteUnit(unit);

      unawaited(
        MasterDataAutoSync.instance.trigger(
          reason: MasterDataAutoSyncReason.unitDeleted,
        ),
      );

      await _loadUnits();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${unit.code} deleted successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on StateError catch (error) {
      _showDeleteError(error.message);
    } on FormatException catch (error) {
      _showDeleteError(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        'Unit soft-delete failed: $error\n$stackTrace',
      );

      _showDeleteError(
        'Unable to delete the unit. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  Future<void> _toggleActive(
    UnitOfMeasure unit,
  ) async {
    await _repository.setUnitActive(
      unit.id,
      !unit.active,
    );

    unawaited(
      MasterDataAutoSync.instance.trigger(
        reason: MasterDataAutoSyncReason.unitStatusChanged,
      ),
    );

    await _loadUnits();
  }

  @override
  Widget build(BuildContext context) {
    final List<UnitOfMeasure> visibleUnits = _filteredUnits;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        title: const Text('Units of Measure'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadUnits,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openUnitForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: _buildContent(visibleUnits),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search unit code or name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadUnits();
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
            onSubmitted: (_) => _loadUnits(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SegmentedButton<UnitStatusFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<UnitStatusFilter>(
                      value: UnitStatusFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment<UnitStatusFilter>(
                      value: UnitStatusFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment<UnitStatusFilter>(
                      value: UnitStatusFilter.inactive,
                      label: Text('Inactive'),
                    ),
                  ],
                  selected: <UnitStatusFilter>{
                    _statusFilter,
                  },
                  onSelectionChanged: (selection) {
                    setState(() {
                      _statusFilter = selection.first;
                    });
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<UnitType?>(
                  value: _unitTypeFilter,
                  hint: const Text('All types'),
                  items: const [
                    DropdownMenuItem<UnitType?>(
                      value: null,
                      child: Text('All types'),
                    ),
                    DropdownMenuItem<UnitType?>(
                      value: UnitType.count,
                      child: Text('Count'),
                    ),
                    DropdownMenuItem<UnitType?>(
                      value: UnitType.weight,
                      child: Text('Weight'),
                    ),
                    DropdownMenuItem<UnitType?>(
                      value: UnitType.volume,
                      child: Text('Volume'),
                    ),
                    DropdownMenuItem<UnitType?>(
                      value: UnitType.packaging,
                      child: Text('Packaging'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _unitTypeFilter = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<UnitOfMeasure> units,
  ) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadUnits,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (units.isEmpty) {
      return const Center(
        child: Text('No units found.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return _UnitTable(
            units: units,
            onEdit: (unit) => _openUnitForm(
              unit: unit,
            ),
            onToggleActive: _toggleActive,
            onDelete: _deleteUnit,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            88,
          ),
          itemCount: units.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final UnitOfMeasure unit = units[index];

            return _UnitCard(
              unit: unit,
              onEdit: () => _openUnitForm(
                unit: unit,
              ),
              onToggleActive: () => _toggleActive(unit),
              onDelete: () => _deleteUnit(unit),
            );
          },
        );
      },
    );
  }
}

class _UnitCard extends StatelessWidget {
  final UnitOfMeasure unit;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _UnitCard({
    required this.unit,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
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
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(
          16,
          10,
          8,
          10,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F1EC),
          child: Text(
            unit.code.substring(0, 1),
            style: const TextStyle(
              color: Color(0xFF2E6B4F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${unit.code} • ${unit.name}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${unitTypeToStorage(unit.unitType)}'
            '${unit.baseUnitCode == null ? '' : ' • '
                '${_formatFactor(unit.conversionFactor)} '
                '${unit.baseUnitCode}'}'
            ' • ${unit.allowDecimal ? 'Decimal' : 'Whole'}',
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }

            if (value == 'toggle') {
              onToggleActive();
            }

            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => [
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
                    unit.active
                        ? Icons.toggle_off_outlined
                        : Icons.toggle_on_outlined,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    unit.active ? 'Deactivate' : 'Activate',
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Color(0xFFA34036),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFFA34036),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitTable extends StatelessWidget {
  final List<UnitOfMeasure> units;
  final Future<void> Function(UnitOfMeasure) onEdit;
  final Future<void> Function(UnitOfMeasure) onDelete;
  final Future<void> Function(UnitOfMeasure) onToggleActive;

  const _UnitTable({
    required this.units,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Base')),
              DataColumn(label: Text('Factor')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: units.map((unit) {
              return DataRow(
                cells: [
                  DataCell(Text(unit.code)),
                  DataCell(Text(unit.name)),
                  DataCell(
                    Text(
                      unitTypeToStorage(unit.unitType),
                    ),
                  ),
                  DataCell(
                    Text(unit.baseUnitCode ?? '—'),
                  ),
                  DataCell(
                    Text(_formatFactor(unit.conversionFactor)),
                  ),
                  DataCell(
                    Text(
                      unit.allowDecimal ? 'Decimal' : 'Whole',
                    ),
                  ),
                  DataCell(
                    Text(
                      unit.active ? 'Active' : 'Inactive',
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => onEdit(unit),
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => onDelete(unit),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFA34036),
                          ),
                        ),
                        IconButton(
                          tooltip: unit.active ? 'Deactivate' : 'Activate',
                          onPressed: () => onToggleActive(unit),
                          icon: Icon(
                            unit.active ? Icons.toggle_on : Icons.toggle_off,
                            color: unit.active
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
