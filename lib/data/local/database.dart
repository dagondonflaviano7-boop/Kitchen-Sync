import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v2.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final String databasePath = join(
      await getDatabasesPath(),
      AppConstants.databaseName,
    );

    return openDatabase(
      databasePath,
      version: AppConstants.databaseVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
      onCreate: (Database db, int version) async {
        await db.transaction((Transaction transaction) async {
          await _runStatements(
            transaction,
            migrationV1,
          );

          if (version >= 2) {
            await _runStatements(
              transaction,
              migrationV2,
            );
          }
        });
      },
      onUpgrade: (
        Database db,
        int oldVersion,
        int newVersion,
      ) async {
        await db.transaction((Transaction transaction) async {
          if (oldVersion < 2 && newVersion >= 2) {
            await _runStatements(
              transaction,
              migrationV2,
            );
          }
        });
      },
    );
  }

  Future<void> _runStatements(
    DatabaseExecutor executor,
    List<String> statements,
  ) async {
    for (final String statement in statements) {
      await executor.execute(statement);
    }
  }

  Future<void> close() async {
    final Database? database = _database;

    if (database != null) {
      await database.close();
      _database = null;
    }
  }
}
