import 'package:kitchen_sync/domain/models/store.dart';
import 'package:sqflite/sqflite.dart';

class StoreDao {
  const StoreDao();

  Future<void> upsert(
    DatabaseExecutor database,
    Store store,
  ) async {
    await database.insert(
      'stores',
      store.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Store?> findById(
    DatabaseExecutor database,
    String storeId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'stores',
      where: 'id = ?',
      whereArgs: <Object?>[storeId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Store.fromSqlite(rows.first);
  }

  Future<List<Store>> findActive(
    DatabaseExecutor database,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'stores',
      where: 'active = ?',
      whereArgs: <Object?>[1],
      orderBy: 'store_name COLLATE NOCASE',
    );

    return rows.map(Store.fromSqlite).toList(growable: false);
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String storeId,
    bool active,
  ) async {
    await database.update(
      'stores',
      <String, Object?>{
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[storeId],
    );
  }
}
