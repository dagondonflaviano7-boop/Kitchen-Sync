import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authorization interface contract', () {
    test('AuthGate loads the remote session context', () {
      final String source = File(
        'lib/features/authentication/presentation/auth_gate.dart',
      ).readAsStringSync();

      expect(
        source.contains('loadAndCacheContext'),
        isTrue,
      );
      expect(
        source.contains('ProfileLoadingScreen'),
        isTrue,
      );
    });

    test('AuthGate passes validated context to the shell', () {
      final String source = File(
        'lib/features/authentication/presentation/auth_gate.dart',
      ).readAsStringSync();

      expect(
        source.contains(
          'AdaptiveShell(',
        ),
        isTrue,
      );
      expect(
        source.contains(
          'sessionContext: snapshot.data!',
        ),
        isTrue,
      );
    });

    test('AuthGate maps all access failures', () {
      final String source = File(
        'lib/features/authentication/presentation/auth_gate.dart',
      ).readAsStringSync();

      const List<String> failures = <String>[
        'profileMissing',
        'profileInvalid',
        'accountInactive',
        'storeMissing',
        'storeInvalid',
        'storeInactive',
        'networkUnavailable',
      ];

      for (final String failure in failures) {
        expect(
          source.contains(
            'SessionAccessFailure.$failure',
          ),
          isTrue,
          reason: 'Missing access failure: $failure',
        );
      }
    });

    test('dashboard displays validated identity', () {
      final String source = File(
        'lib/features/dashboard/presentation/adaptive_shell.dart',
      ).readAsStringSync();

      expect(
        source.contains('sessionContext.profile'),
        isTrue,
      );
      expect(
        source.contains('sessionContext.store'),
        isTrue,
      );
      expect(
        source.contains('roleToStorage'),
        isTrue,
      );
    });

    test('dashboard supports Firebase logout', () {
      final String source = File(
        'lib/features/dashboard/presentation/adaptive_shell.dart',
      ).readAsStringSync();

      expect(
        source.contains('FirebaseAuth.instance.signOut'),
        isTrue,
      );
      expect(
        source.contains("'logout'"),
        isTrue,
      );
    });

    test('dashboard filters destinations by permission', () {
      final String source = File(
        'lib/features/dashboard/presentation/adaptive_shell.dart',
      ).readAsStringSync();

      expect(
        source.contains('hasPermission'),
        isTrue,
      );
      expect(
        source.contains('destination.permission'),
        isTrue,
      );
    });
  });
}
