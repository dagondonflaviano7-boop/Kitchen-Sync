import 'package:flutter/foundation.dart';
import 'package:kitchen_sync/core/constants/app_constants.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v1.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v2.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v3.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v4.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v5.dart';
import 'package:kitchen_sync/data/local/migrations/migration_v6.dart';
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
    final String databasePath = kIsWeb
        ? AppConstants.databaseName
        : join(
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

          if (version >= 3) {
            await _runStatements(
              transaction,
              migrationV3,
            );
          }

          if (version >= 4) {
            await _runStatements(
              transaction,
              migrationV4,
            );
          }

          if (version >= 5) {
            await _runStatements(
              transaction,
              migrationV5,
            );
          }

          if (version >= 6) {
            await _runStatements(
              transaction,
              migrationV6,
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

          if (oldVersion < 3 && newVersion >= 3) {
            await _runStatements(
              transaction,
              migrationV3,
            );
          }

          if (oldVersion < 4 && newVersion >= 4) {
            await _runStatements(
              transaction,
              migrationV4,
            );
          }

          if (oldVersion < 5 && newVersion >= 5) {
            await _runStatements(
              transaction,
              migrationV5,
            );
          }

          if (oldVersion < 6 && newVersion >= 6) {
            await _runStatements(
              transaction,
              migrationV6,
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
