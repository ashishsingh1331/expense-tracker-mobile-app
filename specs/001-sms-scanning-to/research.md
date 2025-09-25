# Research: SMS scanning, category prediction, income & dashboard

Date: 2025-09-25

## Decisions (chosen)
- Platform & Framework: Flutter (single cross-platform codebase for iOS & Android).
- State management: Riverpod for predictable, testable state.
- Local storage: SQLite via `sqflite` as the single source of truth.
- SMS access: `telephony` package to read incoming and past SMS (Android) and an alternate approach on iOS (SMS restricted — use manual import or user paste); document iOS limitation.
- Category prediction: Start with rule-based keyword matching; plan for future TFLite model for offline inference.
- UI & Charts: Start with `syncfusion_flutter_charts` (feature-rich) as primary, allow `charts_flutter` as lighter alternative.
- Sync/Backup: Google Drive API with `.xlsx` export using `excel` package; use Drive OAuth on-device to grant access to a single file/folder.
- Auth: No app-level auth; only Google Drive OAuth for Drive access.
- Testing: Unit tests for business logic, widget tests for UI, one E2E flow covering critical paths.

## Research Notes & Rationale

- Flutter: Good developer velocity, single codebase. Constitution allows cross-platform approaches if documented.
- Riverpod: Lightweight, testable, suits offline-first state and dependency injection.
- sqflite: Simple SQLite access; meets constitution requirement of single local source-of-truth.
- telephony: Android supports SMS read; iOS restricts SMS reading — plan for manual import or notification-based capture. This is a platform constraint; surface to user in settings and README.
- Rule-based prediction first: Low complexity, transparent, easily editable by power-user. TFLite requires training and model lifecycle management; postpone to Phase 2 if uptake warrants it.
- Drive export: `excel` package can write .xlsx; `gsheets` can be used if user prefers Google Sheets API. Choose .xlsx to match user request; allow CSV as alternative export.

## Unknowns / Risks
- iOS SMS access is restricted; cannot reliably scan device SMS on iOS — requires fallback UX.
- Drive OAuth flow complexity: ensure token storage and refresh handled securely on-device.
- Background scheduling for daily export may be constrained by OS battery optimizations (use WorkManager on Android, background fetch on iOS with graceful degradation).

## Next steps (Phase 1 inputs)
- Define data model for Transaction, Income, and Settings.
- Design contracts for sync/export endpoints (local APIs / services) and file format.
- Create quickstart and developer notes for building/running app and Drive setup.
