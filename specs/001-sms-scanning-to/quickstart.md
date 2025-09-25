# Quickstart — SMS scanning feature (developer guide)

## Prerequisites
- Flutter SDK (stable) installed
- Android SDK (for SMS access testing)
- Google Cloud project with Drive API enabled and OAuth credentials for testing (for Drive export)

## Running locally
1. flutter pub get
2. Configure Google Drive OAuth client ID in `lib/config.dart` (local dev override) or set env vars
3. For Android SMS testing, grant SMS read permissions in device/emulator settings
4. flutter run -d <device>

## Tests
- Unit tests: `flutter test test/unit`
- Widget tests: `flutter test test/widgets`
- E2E (one critical flow): `flutter drive --target=test_driver/app.dart`

## Developer notes
- On iOS, SMS access is restricted. Use manual entry flows and test Drive export on simulator with mock data.
- Keep parsing rules in a local JSON file under `assets/parsers/` for curated rules; allow optional user overrides stored in local DB.
