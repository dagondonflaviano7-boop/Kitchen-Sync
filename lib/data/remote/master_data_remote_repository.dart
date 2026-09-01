import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kitchen_sync/domain/models/ingredient.dart';
import 'package:kitchen_sync/domain/models/supplier.dart';
import 'package:kitchen_sync/domain/models/unit_of_measure.dart';

class MasterDataRemoteException implements Exception {
  final String message;
  final Object? cause;

  const MasterDataRemoteException(
    this.message, {
    this.cause,
  });

  @override
  String toString() => message;
}

class MasterDataRemoteRepository {
  static const String unitsNode = 'unitsOfMeasure';
  static const String suppliersNode = 'suppliers';
  static const String ingredientsNode = 'ingredients';

  static const Duration requestTimeout = Duration(seconds: 15);

  final FirebaseDatabase database;

  MasterDataRemoteRepository({
    FirebaseDatabase? database,
  }) : database = database ?? FirebaseDatabase.instance;

  Future<int> uploadUnit(
    UnitOfMeasure unit,
  ) async {
    unit.validate();

    final DatabaseReference reference = database.ref('$unitsNode/${unit.id}');

    final int nextVersion = await _nextServerVersion(
      reference,
      localVersion: unit.serverVersion,
    );

    final Map<String, Object?> payload = Map<String, Object?>.from(
      unit.toFirebase(),
    );

    // syncStatus belongs to local SQLite workflow.
    payload.remove('syncStatus');
    payload['serverVersion'] = nextVersion;

    try {
      await reference.set(payload).timeout(requestTimeout);

      return nextVersion;
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Unit synchronization timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Firebase rejected the Unit update.',
        cause: error,
      );
    }
  }

  Future<int> uploadSupplier(
    Supplier supplier,
  ) async {
    supplier.validate();

    final DatabaseReference reference = database.ref(
      '$suppliersNode/${supplier.id}',
    );

    final int nextVersion = await _nextServerVersion(
      reference,
      localVersion: supplier.serverVersion,
    );

    final Map<String, Object?> payload = Map<String, Object?>.from(
      supplier.toFirebase(),
    );

    // syncStatus belongs to local SQLite workflow.
    payload.remove('syncStatus');
    payload['serverVersion'] = nextVersion;

    try {
      await reference.set(payload).timeout(requestTimeout);

      return nextVersion;
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Supplier synchronization timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Firebase rejected the Supplier update.',
        cause: error,
      );
    }
  }

  Future<int> uploadIngredient(
    Ingredient ingredient,
  ) async {
    ingredient.validate();

    final DatabaseReference reference = database.ref(
      '$ingredientsNode/${ingredient.id}',
    );

    final int nextVersion = await _nextServerVersion(
      reference,
      localVersion: ingredient.serverVersion,
    );

    final Map<String, Object?> payload = Map<String, Object?>.from(
      ingredient.toFirebase(),
    );

    // syncStatus belongs to the local SQLite workflow.
    payload.remove('syncStatus');
    payload['serverVersion'] = nextVersion;

    try {
      await reference.set(payload).timeout(requestTimeout);

      return nextVersion;
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Ingredient synchronization timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Firebase rejected the Ingredient update.',
        cause: error,
      );
    }
  }

  Future<List<UnitOfMeasure>> downloadUnits() async {
    try {
      final DataSnapshot snapshot =
          await database.ref(unitsNode).get().timeout(requestTimeout);

      if (!snapshot.exists || snapshot.value == null) {
        return const <UnitOfMeasure>[];
      }

      final Map<Object?, Object?> records = _requireMap(snapshot.value);

      final List<UnitOfMeasure> units = <UnitOfMeasure>[];

      for (final MapEntry<Object?, Object?> entry in records.entries) {
        final Object? value = entry.value;

        if (value is! Map) {
          continue;
        }

        units.add(
          UnitOfMeasure.fromFirebase(
            entry.key.toString(),
            Map<Object?, Object?>.from(value),
          ),
        );
      }

      return List<UnitOfMeasure>.unmodifiable(units);
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Downloading Units timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Unable to download Units from Firebase.',
        cause: error,
      );
    }
  }

  Future<List<Supplier>> downloadSuppliers() async {
    try {
      final DataSnapshot snapshot =
          await database.ref(suppliersNode).get().timeout(requestTimeout);

      if (!snapshot.exists || snapshot.value == null) {
        return const <Supplier>[];
      }

      final Map<Object?, Object?> records = _requireMap(snapshot.value);

      final List<Supplier> suppliers = <Supplier>[];

      for (final MapEntry<Object?, Object?> entry in records.entries) {
        final Object? value = entry.value;

        if (value is! Map) {
          continue;
        }

        suppliers.add(
          Supplier.fromFirebase(
            entry.key.toString(),
            Map<Object?, Object?>.from(value),
          ),
        );
      }

      return List<Supplier>.unmodifiable(
        suppliers,
      );
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Downloading Suppliers timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Unable to download Suppliers from Firebase.',
        cause: error,
      );
    }
  }

  Future<List<Ingredient>> downloadIngredients() async {
    try {
      final DataSnapshot snapshot =
          await database.ref(ingredientsNode).get().timeout(requestTimeout);

      if (!snapshot.exists || snapshot.value == null) {
        return const <Ingredient>[];
      }

      final Map<Object?, Object?> records = _requireMap(snapshot.value);

      final List<Ingredient> ingredients = <Ingredient>[];

      for (final MapEntry<Object?, Object?> entry in records.entries) {
        final Object? value = entry.value;

        if (value is! Map) {
          continue;
        }

        ingredients.add(
          Ingredient.fromFirebase(
            entry.key.toString(),
            Map<Object?, Object?>.from(value),
          ),
        );
      }

      return List<Ingredient>.unmodifiable(
        ingredients,
      );
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Downloading Ingredients timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Unable to download Ingredients '
        'from Firebase.',
        cause: error,
      );
    }
  }

  Future<int> _nextServerVersion(
    DatabaseReference reference, {
    required int localVersion,
  }) async {
    try {
      final DataSnapshot snapshot =
          await reference.child('serverVersion').get().timeout(requestTimeout);

      int remoteVersion = 0;

      final Object? value = snapshot.value;

      if (value is int) {
        remoteVersion = value;
      } else if (value is num) {
        remoteVersion = value.toInt();
      } else if (value != null) {
        remoteVersion = int.tryParse(value.toString()) ?? 0;
      }

      final int highestVersion =
          remoteVersion > localVersion ? remoteVersion : localVersion;

      return highestVersion + 1;
    } on TimeoutException catch (error) {
      throw MasterDataRemoteException(
        'Reading the remote version timed out.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw MasterDataRemoteException(
        'Unable to read the remote version.',
        cause: error,
      );
    }
  }

  Map<Object?, Object?> _requireMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<Object?, Object?>.from(value);
    }

    throw const MasterDataRemoteException(
      'Firebase Master Data format is invalid.',
    );
  }
}
