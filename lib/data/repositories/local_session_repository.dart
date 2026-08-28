import 'package:kitchen_sync/data/local/daos/store_dao.dart';
import 'package:kitchen_sync/data/local/daos/store_user_assignment_dao.dart';
import 'package:kitchen_sync/data/local/daos/user_profile_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/store.dart';
import 'package:kitchen_sync/domain/models/user_profile.dart';
import 'package:sqflite/sqflite.dart';

class LocalSessionContext {
  final UserProfile profile;
  final Store store;

  const LocalSessionContext({
    required this.profile,
    required this.store,
  });
}

class LocalSessionRepository {
  final StoreDao storeDao;
  final UserProfileDao userProfileDao;
  final StoreUserAssignmentDao assignmentDao;

  const LocalSessionRepository({
    this.storeDao = const StoreDao(),
    this.userProfileDao = const UserProfileDao(),
    this.assignmentDao = const StoreUserAssignmentDao(),
  });

  Future<void> saveContext({
    required UserProfile profile,
    required Store store,
  }) async {
    if (profile.storeId != store.id) {
      throw StateError(
        'The user store assignment does not match the supplied store.',
      );
    }

    final Database database = await AppDatabase.instance.database;

    await database.transaction((Transaction transaction) async {
      await storeDao.upsert(transaction, store);
      await userProfileDao.upsert(transaction, profile);

      await assignmentDao.saveDefaultAssignment(
        transaction,
        userId: profile.id,
        storeId: store.id,
      );
    });
  }

  Future<LocalSessionContext?> loadContext(
    String firebaseUid,
  ) async {
    final Database database = await AppDatabase.instance.database;

    final UserProfile? profile = await userProfileDao.findByFirebaseUid(
      database,
      firebaseUid,
    );

    if (profile == null) {
      return null;
    }

    final Store? store = await storeDao.findById(
      database,
      profile.storeId,
    );

    if (store == null) {
      return null;
    }

    return LocalSessionContext(
      profile: profile,
      store: store,
    );
  }
}
