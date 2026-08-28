import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Remote session repository contract', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/data/repositories/remote_session_repository.dart',
      ).readAsStringSync();
    });

    test('loads the authenticated user profile', () {
      expect(
        source.contains("ref('users/\$firebaseUid')"),
        isTrue,
      );
    });

    test('loads the assigned store', () {
      expect(
        source.contains("ref('stores/\${profile.storeId}')"),
        isTrue,
      );
    });

    test('blocks inactive accounts', () {
      expect(
        source.contains('if (!profile.active)'),
        isTrue,
      );
      expect(
        source.contains('SessionAccessFailure.accountInactive'),
        isTrue,
      );
    });

    test('blocks inactive stores', () {
      expect(
        source.contains('if (!store.active)'),
        isTrue,
      );
      expect(
        source.contains('SessionAccessFailure.storeInactive'),
        isTrue,
      );
    });

    test('saves valid context locally', () {
      expect(
        source.contains('localRepository.saveContext'),
        isTrue,
      );
    });

    test('supports valid offline cached context', () {
      expect(
        source.contains('localRepository.loadContext'),
        isTrue,
      );
      expect(
        source.contains('cached.profile.active'),
        isTrue,
      );
      expect(
        source.contains('cached.store.active'),
        isTrue,
      );
    });
  });
}
