import 'package:kitchen_sync/data/local/daos/supplier_dao.dart';
import 'package:kitchen_sync/data/local/database.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:sqflite/sqflite.dart';

class SupplierRepository {
  final SupplierDao supplierDao;

  const SupplierRepository({
    this.supplierDao = const SupplierDao(),
  });

  Future<List<Supplier>> getSuppliers({
    bool includeInactive = true,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return supplierDao.findAll(
      database,
      includeInactive: includeInactive,
    );
  }

  Future<List<Supplier>> searchSuppliers(
    String query, {
    bool includeInactive = true,
  }) async {
    final Database database = await AppDatabase.instance.database;

    return supplierDao.search(
      database,
      query,
      includeInactive: includeInactive,
    );
  }

  Future<Supplier?> findSupplierById(
    String supplierId,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return supplierDao.findById(
      database,
      supplierId,
    );
  }

  Future<Supplier?> findSupplierByCode(
    String supplierCode,
  ) async {
    final Database database = await AppDatabase.instance.database;

    return supplierDao.findByCode(
      database,
      supplierCode,
    );
  }

  Future<void> saveSupplier(
    Supplier supplier,
  ) async {
    supplier.validate();

    final Database database = await AppDatabase.instance.database;

    final bool duplicate = await supplierDao.codeExists(
      database,
      supplier.supplierCode,
      excludingId: supplier.id,
    );

    if (duplicate) {
      throw StateError(
        'A supplier with code '
        '${supplier.supplierCode.toUpperCase()} '
        'already exists.',
      );
    }

    await supplierDao.upsert(
      database,
      supplier,
    );
  }

  Future<void> setSupplierActive(
    String supplierId,
    bool active,
  ) async {
    final Database database = await AppDatabase.instance.database;

    await supplierDao.setActive(
      database,
      supplierId,
      active,
    );
  }
}
