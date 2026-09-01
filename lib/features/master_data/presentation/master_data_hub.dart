import 'package:flutter/material.dart';
import 'package:kitchen_sync/data/services/master_data_sync_service.dart';
import 'package:kitchen_sync/features/master_data/suppliers/presentation/supplier_screen.dart';
import 'package:kitchen_sync/features/master_data/units/presentation/unit_of_measure_screen.dart';

class MasterDataHub extends StatefulWidget {
  final String currentUserId;

  const MasterDataHub({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MasterDataHub> createState() => _MasterDataHubState();
}

class _MasterDataHubState extends State<MasterDataHub> {
  final MasterDataSyncService _syncService = MasterDataSyncService();

  bool _syncing = false;

  Future<void> _synchronizeMasterData() async {
    if (_syncing || _syncService.isRunning) {
      return;
    }

    setState(() {
      _syncing = true;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Synchronizing master data...',
                ),
              ),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

    try {
      final MasterDataSyncResult result = await _syncService.synchronize();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.offline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No internet connection. '
              'Local changes remain safely stored.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final int uploaded = result.uploadedUnits +
          result.uploadedSuppliers +
          result.uploadedIngredients;

      final int downloaded = result.downloadedUnits +
          result.downloadedSuppliers +
          result.downloadedIngredients;

      final String message = result.errors == 0
          ? 'Master data synchronized successfully. '
              '$uploaded uploaded, $downloaded downloaded, '
              'and ${result.preservedLocalChanges} '
              'local change(s) preserved.'
          : 'Synchronization completed with '
              '${result.errors} error(s). '
              '$uploaded uploaded, $downloaded downloaded, '
              'and ${result.preservedLocalChanges} '
              'local change(s) preserved.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result.errors == 0
              ? const Color(0xFF2E6B4F)
              : const Color(0xFFA15C22),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error, stackTrace) {
      debugPrint(
        'Master Data synchronization failed: '
        '$error\n$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to synchronize master data. '
              'Local changes remain safely stored.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 28 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HubHeader(),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: wide ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: wide ? 2.25 : 2.5,
                        children: [
                          _MasterDataCard(
                            title: 'Units of Measure',
                            subtitle: 'Manage units, measurement types, '
                                'and universal conversions.',
                            icon: Icons.straighten,
                            color: const Color(0xFF2E6B4F),
                            enabled: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const UnitOfMeasureScreen(),
                                ),
                              );
                            },
                          ),
                          _MasterDataCard(
                            title: 'Suppliers',
                            subtitle: 'Manage supplier records, contacts, '
                                'terms, and lead times.',
                            icon: Icons.local_shipping_outlined,
                            color: const Color(0xFF4D6588),
                            enabled: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SupplierScreen(
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                            },
                          ),
                          _MasterDataCard(
                            title: _syncing
                                ? 'Synchronizing...'
                                : 'Sync Master Data',
                            subtitle: _syncing
                                ? 'Uploading local changes and '
                                    'downloading Firebase updates.'
                                : 'Synchronize Units of Measure, '
                                    'Suppliers, and Ingredients '
                                    'with Firebase.',
                            icon: _syncing
                                ? Icons.sync
                                : Icons.cloud_sync_outlined,
                            color: const Color(0xFF4F46E5),
                            enabled: !_syncing,
                            onTap: _synchronizeMasterData,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Master Data',
          style: TextStyle(
            color: Color(0xFF183027),
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Configure the records used across Kitchen Sync.',
          style: TextStyle(
            color: Color(0xFF64756B),
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _MasterDataCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _MasterDataCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = enabled ? color : const Color(0xFF8A958E);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFDBE5DD),
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF183027),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!enabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2EF),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'COMING NEXT',
                              style: TextStyle(
                                color: Color(0xFF6D7D73),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: effectiveColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64756B),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
