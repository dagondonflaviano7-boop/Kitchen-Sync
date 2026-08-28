import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class StoreUserAssignmentDao {
  const StoreUserAssignmentDao();

  Future<void> saveDefaultAssignment(
    DatabaseExecutor database, {
    required String userId,
    required String storeId,
  }) async {
    final String now = DateTime.now().toUtc().toIso8601String();

    await database.update(
      'store_user_assignments',
      <String, Object?>{
        'is_default': 0,
        'updated_at': now,
      },
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
    );

    await database.insert(
      'store_user_assignments',
      <String, Object?>{
        'id': const Uuid().v4(),
        'user_id': userId,
        'store_id': storeId,
        'is_default': 1,
        'active': 1,
        'sync_status': 'SYNCED',
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await database.update(
      'store_user_assignments',
      <String, Object?>{
        'is_default': 1,
        'active': 1,
        'sync_status': 'SYNCED',
        'updated_at': now,
      },
      where: 'user_id = ? AND store_id = ?',
      whereArgs: <Object?>[userId, storeId],
    );
  }

  Future<String?> findDefaultStoreId(
    DatabaseExecutor database,
    String userId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'store_user_assignments',
      columns: <String>['store_id'],
      where: 'user_id = ? AND is_default = ? AND active = ?',
      whereArgs: <Object?>[userId, 1, 1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['store_id']?.toString();
  }
}
