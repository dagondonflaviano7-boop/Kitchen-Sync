# KITCHEN SYNC

Phase 1 foundation for an offline-first Android phone/tablet business app.

## Included
- Modular Flutter structure and Material 3 theme
- SQLite v1 schema with foreign keys, WAL, constraints and indexes
- Firebase Auth gate and RTDB service
- Persistent generated device UUID
- Network plus actual-internet detection
- Phone bottom navigation and tablet NavigationRail
- Cloudinary upload service without API secret
- Idempotent sync queue foundation
- Draft RTDB rules and schema tests

## Codespaces setup
1. Install Flutter stable and Android SDK in the Codespace/dev container.
2. Run `flutter pub get`.
3. Run `flutterfire configure` and select Android + Realtime Database; this generates `lib/firebase_options.dart` and `android/app/google-services.json`. Update `main.dart` to pass `DefaultFirebaseOptions.currentPlatform` if generated.
4. Create `.env` from `.env.example`; do not commit secrets. A production app should use compile-time defines or a secret-injection layer rather than parsing a committed file.
5. Create a restricted Cloudinary upload preset for development, or a server-signed endpoint for production.
6. Run `flutter test`, then `flutter run`.
7. Build `flutter build apk --release` and `flutter build appbundle --release` after signing is configured.

## Required Firebase profile
`users/{firebaseUid}` must contain: userId, name, role, storeId, active. Role values must exactly match the rules.

## Important
This package intentionally stops at Phase 1. The POS buttons are navigation placeholders and contain no fake transaction processing. Firebase credentials, Cloudinary account values, release signing and generated Flutter Android wrapper files must be supplied in the configured development environment.
