import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:kitchen_sync/data/local/database.dart';

class SyncManager {
  final FirebaseDatabase remote;
  SyncManager({FirebaseDatabase? remote})
      : remote = remote ?? FirebaseDatabase.instance;
  bool _running = false;
  Future<void> pushPending() async {
    if (_running) return;
    _running = true;
    final db = await AppDatabase.instance.database;
    try {
      final rows = await db.query('sync_queue',
          where: 'status IN (?,?)',
          whereArgs: ['PENDING', 'ERROR'],
          orderBy: 'created_at',
          limit: 100);
      for (final row in rows) {
        await _pushOne(db, row);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _pushOne(Database db, Map<String, Object?> row) async {
    final id = row['id'] as String;
    try {
      await db.update('sync_queue', {'status': 'SYNCING'},
          where: 'id=?', whereArgs: [id]);
      final entityType = row['entity_type'] as String,
          entityId = row['entity_id'] as String;
      final ref = remote.ref('${_node(entityType)}/$entityId');
      final existing = await ref.get();
      if (!existing.exists) await ref.set(jsonDecode(row['payload'] as String));
      await db.update(
          'sync_queue',
          {
            'status': 'SYNCED',
            'synced_at': DateTime.now().toUtc().toIso8601String(),
            'last_error': null
          },
          where: 'id=?',
          whereArgs: [id]);
    } catch (e) {
      await db.rawUpdate(
          'UPDATE sync_queue SET status=?, retry_count=retry_count+1, last_error=? WHERE id=?',
          ['ERROR', e.toString(), id]);
    }
  }

  String _node(String type) => switch (type) {
        'SALE' => 'sales',
        'PAYMENT' => 'payments',
        'PRODUCT' => 'products',
        'INGREDIENT' => 'ingredients',
        'RECIPE' => 'recipes',
        'INVENTORY' => 'inventory',
        'RECEIVING' => 'receiving',
        'ADJUSTMENT' => 'adjustments',
        'CASHIER_SESSION' => 'cashierSessions',
        'CASHIER_REPORT' => 'cashierReports',
        'COSTING' => 'costing',
        'AUDIT_LOG' => 'auditLogs',
        _ => type.toLowerCase()
      };
}
