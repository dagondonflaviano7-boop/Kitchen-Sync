import 'package:kitchen_sync/domain/models/user_profile.dart';
import 'package:sqflite/sqflite.dart';

class UserProfileDao {
  const UserProfileDao();

  Future<void> upsert(
    DatabaseExecutor database,
    UserProfile profile,
  ) async {
    await database.insert(
      'users',
      profile.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> findById(
    DatabaseExecutor database,
    String userId,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: <Object?>[userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserProfile.fromSqlite(rows.first);
  }

  Future<UserProfile?> findByFirebaseUid(
    DatabaseExecutor database,
    String firebaseUid,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: <Object?>[firebaseUid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserProfile.fromSqlite(rows.first);
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String userId,
    bool active,
  ) async {
    await database.update(
      'users',
      <String, Object?>{
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
  }
}
