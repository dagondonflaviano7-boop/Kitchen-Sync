import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

void main() {
  final DateTime timestamp = DateTime.utc(2026, 8, 28);

  Supplier createSupplier({
    String code = 'SUP001',
    String name = 'Cebu Food Supply',
    String? email = 'orders@example.com',
    int leadTimeDays = 3,
  }) {
    return Supplier(
      id: 'SUPPLIER-001',
      supplierCode: code,
      supplierName: name,
      contactPerson: 'Purchasing Contact',
      phone: '09171234567',
      email: email,
      address: 'Cebu',
      taxId: 'TIN-001',
      paymentTerms: 'NET 30',
      leadTimeDays: leadTimeDays,
      active: true,
      createdAt: timestamp,
      updatedAt: timestamp,
      createdBy: 'ADMIN',
      updatedBy: 'ADMIN',
    );
  }

  group('Supplier model', () {
    test('maps to SQLite columns', () {
      final Map<String, Object?> map = createSupplier().toSqlite();

      expect(map['supplier_code'], 'SUP001');
      expect(
        map['supplier_name'],
        'Cebu Food Supply',
      );
      expect(map['lead_time_days'], 3);
      expect(map['active'], 1);
      expect(map['sync_status'], 'PENDING');
    });

    test('maps to Firebase fields', () {
      final Map<String, Object?> map = createSupplier().toFirebase();

      expect(map['supplierCode'], 'SUP001');
      expect(
        map['supplierName'],
        'Cebu Food Supply',
      );
      expect(map['leadTimeDays'], 3);
      expect(map['active'], isTrue);
    });

    test('parses a SQLite supplier', () {
      final Supplier supplier = Supplier.fromSqlite(
        <String, Object?>{
          'id': 'SUPPLIER-001',
          'supplier_code': 'SUP001',
          'supplier_name': 'Cebu Food Supply',
          'contact_person': 'Purchasing Contact',
          'phone': '09171234567',
          'email': 'orders@example.com',
          'address': 'Cebu',
          'tax_id': 'TIN-001',
          'payment_terms': 'NET 30',
          'lead_time_days': 3,
          'active': 1,
          'created_at': timestamp.toIso8601String(),
          'updated_at': timestamp.toIso8601String(),
          'created_by': 'ADMIN',
          'updated_by': 'ADMIN',
          'sync_status': 'SYNCED',
          'server_version': 2,
          'deleted_at': null,
        },
      );

      expect(supplier.supplierCode, 'SUP001');
      expect(supplier.active, isTrue);
      expect(
        supplier.syncStatus,
        MasterSyncStatus.synced,
      );
    });

    test('rejects an empty supplier code', () {
      final Supplier supplier = createSupplier(code: '');

      expect(
        supplier.validate,
        throwsFormatException,
      );
    });

    test('rejects invalid code characters', () {
      final Supplier supplier = createSupplier(code: 'SUP-001');

      expect(
        supplier.validate,
        throwsFormatException,
      );
    });

    test('rejects an empty supplier name', () {
      final Supplier supplier = createSupplier(name: ' ');

      expect(
        supplier.validate,
        throwsFormatException,
      );
    });

    test('rejects a negative lead time', () {
      final Supplier supplier = createSupplier(leadTimeDays: -1);

      expect(
        supplier.validate,
        throwsFormatException,
      );
    });

    test('rejects an invalid email', () {
      final Supplier supplier = createSupplier(email: 'invalid-email');

      expect(
        supplier.validate,
        throwsFormatException,
      );
    });

    test('allows an empty optional email', () {
      final Supplier supplier = createSupplier(email: null);

      expect(
        supplier.validate,
        returnsNormally,
      );
    });

    test('copyWith preserves unchanged identity', () {
      final Supplier original = createSupplier();

      final Supplier updated = original.copyWith(
        supplierName: 'Updated Supplier',
        active: false,
      );

      expect(updated.id, original.id);
      expect(
        updated.createdAt,
        original.createdAt,
      );
      expect(
        updated.supplierName,
        'Updated Supplier',
      );
      expect(updated.active, isFalse);
    });
  });
}
