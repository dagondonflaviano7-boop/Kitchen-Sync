import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kitchen_sync/data/repositories/local_session_repository.dart';
import 'package:kitchen_sync/domain/models/store.dart';
import 'package:kitchen_sync/domain/models/user_profile.dart';

enum SessionAccessFailure {
  profileMissing,
  profileInvalid,
  accountInactive,
  storeMissing,
  storeInvalid,
  storeInactive,
  networkUnavailable,
}

class SessionAccessException implements Exception {
  final SessionAccessFailure failure;
  final String message;
  final Object? cause;

  const SessionAccessException(
    this.failure,
    this.message, {
    this.cause,
  });

  @override
  String toString() => message;
}

class RemoteSessionRepository {
  final FirebaseDatabase database;
  final LocalSessionRepository localRepository;

  RemoteSessionRepository({
    FirebaseDatabase? database,
    LocalSessionRepository? localRepository,
  })  : database = database ?? FirebaseDatabase.instance,
        localRepository = localRepository ?? const LocalSessionRepository();

  Future<LocalSessionContext> loadAndCacheContext(
    String firebaseUid,
  ) async {
    try {
      final DataSnapshot profileSnapshot = await database
          .ref('users/$firebaseUid')
          .get()
          .timeout(const Duration(seconds: 15));

      if (!profileSnapshot.exists || profileSnapshot.value == null) {
        throw const SessionAccessException(
          SessionAccessFailure.profileMissing,
          'Your Kitchen Sync user profile is not configured.',
        );
      }

      final Map<Object?, Object?> profileMap =
          _requireMap(profileSnapshot.value);

      final UserProfile profile;

      try {
        profile = UserProfile.fromFirebase(
          firebaseUid,
          profileMap,
        );
      } on FormatException catch (error) {
        throw SessionAccessException(
          SessionAccessFailure.profileInvalid,
          'Your Kitchen Sync user profile is invalid.',
          cause: error,
        );
      }

      if (!profile.active) {
        throw const SessionAccessException(
          SessionAccessFailure.accountInactive,
          'Your Kitchen Sync account is inactive.',
        );
      }

      final DataSnapshot storeSnapshot = await database
          .ref('stores/${profile.storeId}')
          .get()
          .timeout(const Duration(seconds: 15));

      if (!storeSnapshot.exists || storeSnapshot.value == null) {
        throw const SessionAccessException(
          SessionAccessFailure.storeMissing,
          'The assigned store configuration was not found.',
        );
      }

      final Map<Object?, Object?> storeMap = _requireMap(storeSnapshot.value);

      final Store store;

      try {
        store = Store.fromFirebase(
          profile.storeId,
          storeMap,
        );
      } on FormatException catch (error) {
        throw SessionAccessException(
          SessionAccessFailure.storeInvalid,
          'The assigned store configuration is invalid.',
          cause: error,
        );
      }

      if (!store.active) {
        throw const SessionAccessException(
          SessionAccessFailure.storeInactive,
          'The assigned store is inactive.',
        );
      }

      await localRepository.saveContext(
        profile: profile,
        store: store,
      );

      return LocalSessionContext(
        profile: profile,
        store: store,
      );
    } on SessionAccessException {
      rethrow;
    } on TimeoutException catch (error) {
      final LocalSessionContext? cached =
          await localRepository.loadContext(firebaseUid);

      if (cached != null && cached.profile.active && cached.store.active) {
        return cached;
      }

      throw SessionAccessException(
        SessionAccessFailure.networkUnavailable,
        'Kitchen Sync could not verify access within '
        'the allowed time.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      final LocalSessionContext? cached =
          await localRepository.loadContext(firebaseUid);

      if (cached != null && cached.profile.active && cached.store.active) {
        return cached;
      }

      throw SessionAccessException(
        SessionAccessFailure.networkUnavailable,
        'Kitchen Sync could not load the user and store profile.',
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

    throw const SessionAccessException(
      SessionAccessFailure.profileInvalid,
      'The Firebase profile format is invalid.',
    );
  }
}
