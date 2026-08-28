import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:sqflite/sqflite.dart';

class SupplierDao {
  const SupplierDao();

  Future<void> upsert(
    DatabaseExecutor database,
    Supplier supplier,
  ) async {
    await database.insert(
      'suppliers',
      supplier.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Supplier?> findById(
    DatabaseExecutor database,
    String id,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Supplier.fromSqlite(rows.first);
  }

  Future<Supplier?> findByCode(
    DatabaseExecutor database,
    String supplierCode,
  ) async {
    final List<Map<String, Object?>> rows = await database.query(
      'suppliers',
      where: 'supplier_code = ?',
      whereArgs: <Object?>[
        supplierCode.trim().toUpperCase(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Supplier.fromSqlite(rows.first);
  }

  Future<List<Supplier>> findAll(
    DatabaseExecutor database, {
    bool includeInactive = true,
  }) async {
    final List<Map<String, Object?>> rows = await database.query(
      'suppliers',
      where: includeInactive
          ? 'deleted_at IS NULL'
          : 'active = ? AND deleted_at IS NULL',
      whereArgs: includeInactive ? null : <Object?>[1],
      orderBy: 'supplier_name COLLATE NOCASE, supplier_code',
    );

    return rows.map(Supplier.fromSqlite).toList(growable: false);
  }

  Future<List<Supplier>> search(
    DatabaseExecutor database,
    String query, {
    bool includeInactive = true,
  }) async {
    final String searchText = query.trim();

    if (searchText.isEmpty) {
      return findAll(
        database,
        includeInactive: includeInactive,
      );
    }

    String where = '(supplier_code LIKE ? '
        'OR supplier_name LIKE ? '
        'OR contact_person LIKE ? '
        'OR phone LIKE ?) '
        'AND deleted_at IS NULL';

    final List<Object?> arguments = <Object?>[
      '%$searchText%',
      '%$searchText%',
      '%$searchText%',
      '%$searchText%',
    ];

    if (!includeInactive) {
      where = '$where AND active = ?';
      arguments.add(1);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'suppliers',
      where: where,
      whereArgs: arguments,
      orderBy: 'supplier_name COLLATE NOCASE, supplier_code',
    );

    return rows.map(Supplier.fromSqlite).toList(growable: false);
  }

  Future<bool> codeExists(
    DatabaseExecutor database,
    String supplierCode, {
    String? excludingId,
  }) async {
    String where = 'supplier_code = ? AND deleted_at IS NULL';

    final List<Object?> arguments = <Object?>[
      supplierCode.trim().toUpperCase(),
    ];

    if (excludingId != null && excludingId.trim().isNotEmpty) {
      where = '$where AND id != ?';
      arguments.add(excludingId);
    }

    final List<Map<String, Object?>> rows = await database.query(
      'suppliers',
      columns: <String>['id'],
      where: where,
      whereArgs: arguments,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> setActive(
    DatabaseExecutor database,
    String supplierId,
    bool active,
  ) async {
    final int updated = await database.update(
      'suppliers',
      <String, Object?>{
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sync_status': 'PENDING',
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: <Object?>[supplierId],
    );

    if (updated == 0) {
      throw StateError(
        'The supplier record was not found.',
      );
    }
  }
}
