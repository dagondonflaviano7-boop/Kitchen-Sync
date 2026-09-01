import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kitchen_sync/data/services/master_data_sync_service.dart';

enum MasterDataAutoSyncReason {
  login,
  appResume,
  connectivityRestored,
  unitSaved,
  unitStatusChanged,
  unitDeleted,
  supplierSaved,
  supplierStatusChanged,
  supplierDeleted,
  ingredientSaved,
  ingredientStatusChanged,
  ingredientDeleted,
  manual,
}

class MasterDataAutoSync {
  MasterDataAutoSync._();

  static final MasterDataAutoSync instance = MasterDataAutoSync._();

  final MasterDataSyncService _syncService = MasterDataSyncService();

  Future<MasterDataSyncResult?>? _activeSync;
  DateTime? _lastStartedAt;

  static const Duration _minimumInterval = Duration(seconds: 3);

  bool get isRunning {
    return _activeSync != null || _syncService.isRunning;
  }

  Future<MasterDataSyncResult?> trigger({
    required MasterDataAutoSyncReason reason,
    bool force = false,
  }) {
    final Future<MasterDataSyncResult?>? running = _activeSync;

    if (running != null) {
      debugPrint(
        '[MASTER_DATA_AUTO_SYNC] Existing sync reused. '
        'Reason: ${reason.name}',
      );

      return running;
    }

    final DateTime now = DateTime.now();
    final DateTime? lastStartedAt = _lastStartedAt;

    if (!force &&
        lastStartedAt != null &&
        now.difference(lastStartedAt) < _minimumInterval) {
      debugPrint(
        '[MASTER_DATA_AUTO_SYNC] Trigger throttled. '
        'Reason: ${reason.name}',
      );

      return Future<MasterDataSyncResult?>.value(
        null,
      );
    }

    _lastStartedAt = now;

    final Future<MasterDataSyncResult?> operation = _run(reason);

    _activeSync = operation;

    operation.whenComplete(() {
      if (identical(_activeSync, operation)) {
        _activeSync = null;
      }
    });

    return operation;
  }

  Future<MasterDataSyncResult?> _run(
    MasterDataAutoSyncReason reason,
  ) async {
    debugPrint(
      '[MASTER_DATA_AUTO_SYNC] Started. '
      'Reason: ${reason.name}',
    );

    try {
      final MasterDataSyncResult result = await _syncService.synchronize();

      if (result.offline) {
        debugPrint(
          '[MASTER_DATA_AUTO_SYNC] Offline. '
          'Local changes remain stored.',
        );

        return result;
      }

      debugPrint(
        '[MASTER_DATA_AUTO_SYNC] Completed. '
        'Reason: ${reason.name}; '
        'units uploaded: ${result.uploadedUnits}; '
        'suppliers uploaded: '
        '${result.uploadedSuppliers}; '
        'ingredients uploaded: '
        '${result.uploadedIngredients}; '
        'units downloaded: '
        '${result.downloadedUnits}; '
        'suppliers downloaded: '
        '${result.downloadedSuppliers}; '
        'ingredients downloaded: '
        '${result.downloadedIngredients}; '
        'preserved: '
        '${result.preservedLocalChanges}; '
        'errors: ${result.errors}.',
      );

      return result;
    } on StateError catch (error, stackTrace) {
      debugPrint(
        '[MASTER_DATA_AUTO_SYNC] State error: '
        '$error\n$stackTrace',
      );

      return null;
    } catch (error, stackTrace) {
      debugPrint(
        '[MASTER_DATA_AUTO_SYNC] Failed: '
        '$error\n$stackTrace',
      );

      return null;
    }
  }
}
