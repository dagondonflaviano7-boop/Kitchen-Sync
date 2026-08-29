import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

void main() {
  final DateTime createdAt = DateTime.utc(2026, 8, 28);

  final DateTime deletedAt = DateTime.utc(2026, 8, 29, 2, 30);

  group('Master Data deletion tombstones', () {
    test('Unit serializes deletedAt to SQLite', () {
      final UnitOfMeasure unit = UnitOfMeasure(
        id: 'UOM-TRAY',
        code: 'TRAY',
        name: 'Tray',
        unitType: UnitType.packaging,
        baseUnitCode: null,
        conversionFactor: 1,
        allowDecimal: false,
        active: false,
        createdAt: createdAt,
        updatedAt: deletedAt,
        syncStatus: MasterSyncStatus.pending,
        serverVersion: 0,
        deletedAt: deletedAt,
      );

      final Map<String, Object?> map = unit.toSqlite();

      expect(map['active'], 0);
      expect(
        map['deleted_at'],
        deletedAt.toIso8601String(),
      );
      expect(
        map['updated_at'],
        deletedAt.toIso8601String(),
      );
      expect(map['sync_status'], 'PENDING');
    });

    test('Unit serializes deletedAt to Firebase', () {
      final UnitOfMeasure unit = UnitOfMeasure(
        id: 'UOM-TRAY',
        code: 'TRAY',
        name: 'Tray',
        unitType: UnitType.packaging,
        baseUnitCode: null,
        conversionFactor: 1,
        allowDecimal: false,
        active: false,
        createdAt: createdAt,
        updatedAt: deletedAt,
        syncStatus: MasterSyncStatus.pending,
        serverVersion: 0,
        deletedAt: deletedAt,
      );

      final Map<String, Object?> map = unit.toFirebase();

      expect(map['active'], isFalse);
      expect(
        map['deletedAt'],
        deletedAt.toIso8601String(),
      );
      expect(map['syncStatus'], 'PENDING');
    });

    test('Supplier serializes deletion audit to SQLite', () {
      final Supplier supplier = Supplier(
        id: 'SUPPLIER-001',
        supplierCode: 'SUP001',
        supplierName: 'Cebu Food Supply',
        contactPerson: null,
        phone: null,
        email: null,
        address: null,
        taxId: null,
        paymentTerms: null,
        leadTimeDays: 3,
        active: false,
        createdAt: createdAt,
        updatedAt: deletedAt,
        createdBy: 'USER-CREATOR',
        updatedBy: 'USER-DELETER',
        syncStatus: MasterSyncStatus.pending,
        serverVersion: 0,
        deletedAt: deletedAt,
      );

      final Map<String, Object?> map = supplier.toSqlite();

      expect(map['active'], 0);
      expect(
        map['deleted_at'],
        deletedAt.toIso8601String(),
      );
      expect(map['updated_by'], 'USER-DELETER');
      expect(map['sync_status'], 'PENDING');
    });

    test('Supplier serializes deletion audit to Firebase', () {
      final Supplier supplier = Supplier(
        id: 'SUPPLIER-001',
        supplierCode: 'SUP001',
        supplierName: 'Cebu Food Supply',
        contactPerson: null,
        phone: null,
        email: null,
        address: null,
        taxId: null,
        paymentTerms: null,
        leadTimeDays: 3,
        active: false,
        createdAt: createdAt,
        updatedAt: deletedAt,
        createdBy: 'USER-CREATOR',
        updatedBy: 'USER-DELETER',
        syncStatus: MasterSyncStatus.pending,
        serverVersion: 0,
        deletedAt: deletedAt,
      );

      final Map<String, Object?> map = supplier.toFirebase();

      expect(map['active'], isFalse);
      expect(
        map['deletedAt'],
        deletedAt.toIso8601String(),
      );
      expect(map['updatedBy'], 'USER-DELETER');
      expect(map['syncStatus'], 'PENDING');
    });

    test('non-deleted records serialize null tombstones', () {
      final Supplier supplier = Supplier(
        id: 'SUPPLIER-002',
        supplierCode: 'SUP002',
        supplierName: 'Active Supplier',
        contactPerson: null,
        phone: null,
        email: null,
        address: null,
        taxId: null,
        paymentTerms: null,
        leadTimeDays: 0,
        active: true,
        createdAt: createdAt,
        updatedAt: createdAt,
        createdBy: 'USER-CREATOR',
        updatedBy: 'USER-CREATOR',
      );

      expect(
        supplier.toSqlite()['deleted_at'],
        isNull,
      );

      expect(
        supplier.toFirebase()['deletedAt'],
        isNull,
      );
    });
  });
}
