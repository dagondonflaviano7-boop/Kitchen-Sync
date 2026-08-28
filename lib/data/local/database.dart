import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _db;
  Future<Database> get database async => _db ??= await _open();
  Future<Database> _open() async => openDatabase(
        join(await getDatabasesPath(), AppConstants.databaseName),
        version: AppConstants.databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
        },
        onCreate: (db, version) async {
          for (final sql in migrationV1) {
            await db.execute(sql);
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Future migrations: apply each version once, in order, in a transaction.
        },
      );
}
