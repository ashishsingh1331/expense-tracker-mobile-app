# Actionable Tasks (T001..) — SMS scanning, category prediction, income & dashboard

Project feature dir: `/Users/ashish/code/personal/spec-kit-practice/expense-tracker/specs/001-sms-scanning-to`

Ordering rules applied: setup → tests → models → services → UI → integration → polish. [P] indicates tasks that can run in parallel (different files).

Each task below is written so an LLM or developer can complete it without additional context. File paths are relative to the repo root.

## Setup & CI

T001 [P] ✅ — Create Flutter project skeleton (if not present)
- Files to create: `lib/`, `lib/models/`, `lib/services/`, `lib/ui/`, `test/`, `assets/parsers/`, `android/` (if Android-specific code required)
- Deliverable: commit that adds folder skeleton and README note.
- Dependencies: none
- Command example: git checkout -b 001-sms-scanning-to-skel && mkdir -p lib/models lib/services lib/ui test assets/parsers && git add . && git commit -m "feat(skeleton): add feature skeleton"

T002 [P] ✅ — Add project dependencies to `pubspec.yaml`
- Files to modify: `pubspec.yaml`
- Add dependencies: riverpod, sqflite, path_provider, telephony (Android only), syncfusion_flutter_charts, excel (or gsheets), flutter_local_notifications (for scheduling fallback), mockito (dev)
- Deliverable: updated `pubspec.yaml` with versions pinned and `flutter pub get` passes.

T003 ✅ — Add CI job (GitHub Actions) to run `flutter test` and a basic analyzer
- Files to create: `.github/workflows/ci.yml`
- Deliverable: GH Actions workflow that runs `flutter pub get` and `flutter test` on PRs.

## Models & Persistence (TDD first)

T004 [P] ✅ — Create migration and SQLite schema for `transactions`, `income`, `user_settings`
- Files to create: `lib/services/db/migrations.dart`, `lib/services/db/schema.sql`
- Requirements: create tables matching `data-model.md` fields; include indexes on `date`,`amount`,`merchant`.
- Tests: `test/unit/db_migration_test.dart` that asserts tables exist after migration.

T005 [P] ✅ — Implement `Transaction` model class with toMap/fromMap and validation
- Files to create: `lib/models/transaction.dart`, `test/unit/transaction_test.dart`
- Deliverable: class fields from `data-model.md`, `validate()` method, tests for amount>0 and date parsing.

T006 [P] ✅ — Implement `Income` model class with recurrence handling
- Files: `lib/models/income.dart`, `test/unit/income_test.dart`
- Deliverable: recurrence enum, `nextDate()` logic, tests for monthly recurrence.

T007 [P] ✅ — Implement `UserSettings` model persistence helpers
- Files: `lib/models/user_settings.dart`, `test/unit/user_settings_test.dart`
- Deliverable: store/retrieve `backup_file_id`, `last_sync_at`, and parsing prefs.

## Parsing & SMS Ingestion

T008 ✅ — Implement parsing rule loader (curated rules from `assets/parsers/*.json`) and custom-rule store
- Files: `lib/services/parsing/rule_loader.dart`, `assets/parsers/example_rules.json`, `test/unit/rule_loader_test.dart`
- Deliverable: load curated JSON rules and persist custom rules in `user_settings` table.

T009 — Unit tests for parsing rules and simple pattern matching
- Files: `test/unit/parsing_test.dart`
- Deliverable: tests that exercise pattern matching and precedence.

T010 — Implement SMS ingestion service for Android using `telephony`
- Files: `lib/services/sms/sms_service.dart`, `test/unit/sms_service_test.dart` (mock telephony)
- Important: iOS note — method should fail gracefully and expose manual import flow.

T011 — Implement SMS parsing pipeline: raw SMS → list of candidate Transactions
- Files: `lib/services/parsing/parsing_pipeline.dart`, `test/unit/parsing_pipeline_test.dart`
- Deliverable: handle multi-transaction SMS, ambiguous amounts flagged as tentative.

## Category Prediction & Feedback

T012 [P] — Implement category prediction service (rule-based) with pluggable interface
- Files: `lib/services/prediction/predictor.dart`, `test/unit/predictor_test.dart`
- Deliverable: keyword matcher that returns top predicted category and confidence score.

T013 — Implement feedback recording: store user corrections to influence heuristics
- Files: `lib/services/prediction/feedback_store.dart`, `test/unit/feedback_test.dart`

T014 — Unit tests for prediction + feedback integration
- Files: `test/unit/prediction_integration_test.dart`

## Repositories & Contracts

T015 — Implement `TransactionRepository` with CRUD and deduplication heuristics
- Files: `lib/services/repository/transaction_repository.dart`, `test/unit/transaction_repository_test.dart`
- Dedup rules: use `transaction_id` if present else (date within 48h, amount exact, merchant fuzzy match)

T016 [P] — Create contract tests from `contracts/transactions.post.json` and `contracts/drive.export.post.json`
- Files: `test/contracts/transactions_post_contract_test.dart`, `test/contracts/drive_export_contract_test.dart`
- Deliverable: failing contract tests that assert request/response shapes.

## UI & ViewModels (Riverpod)

T017 — Manual entry screen UI + ViewModel (Riverpod)
- Files: `lib/ui/manual_entry/manual_entry_page.dart`, `lib/ui/manual_entry/manual_entry_viewmodel.dart`, `test/widgets/manual_entry_test.dart`
- Deliverable: form with fields date, amount, merchant, category, notes; saves to repository.

T018 — Recurring income UI + ViewModel
- Files: `lib/ui/income/income_page.dart`, `lib/ui/income/income_viewmodel.dart`, `test/unit/income_widget_test.dart`

T019 ✅ — Dashboard provider: monthly aggregation, category breakdown, top merchants
- Files: `lib/ui/dashboard/dashboard_viewmodel.dart`, `test/unit/dashboard_test.dart`
- Completed: Implemented DashboardViewModel with monthly summary, category breakdown, and top merchants support

T020 — Dashboard UI with charts integration (syncfusion)
- Files: `lib/ui/dashboard/dashboard_page.dart`, `test/widgets/dashboard_widget_test.dart`

## Drive Export & Scheduling

T021 — Implement Drive export service (.xlsx assembly + Drive append)
- Files: `lib/services/drive/drive_export_service.dart`, `test/integration/drive_export_test.dart` (mock Drive)

T022 — Implement background scheduling for daily export (Android WorkManager wrapper + iOS fallback)
- Files: `lib/services/scheduling/scheduler.dart`, `test/unit/scheduler_test.dart`

T023 — Integration tests for export flow with deduplication behavior
- Files: `test/integration/export_integration_test.dart`

T024 — Add manual "Run backup now" action in settings and UI
- Files: `lib/ui/settings/settings_page.dart`, `test/widgets/settings_test.dart`

## Observability, CI & Polish

T025 — Implement logging hooks (no PII) and error reporting toggles
- Files: `lib/services/logging/logger.dart`, `test/unit/logger_test.dart`

T026 — Add CI workflow for unit/widget tests and a smoke E2E job
- Files: `.github/workflows/ci.yml` (enhance from T003), `test/e2e/critical_flow.dart`

T027 — Create E2E test: SMS ingestion (mock), category correction, manual entry, dashboard open, run backup (mock)
- Files: `test_driver/e2e_critical_flow.dart`

T028 — Documentation: update `specs/001-sms-scanning-to/README.md` with Quickstart and Drive setup notes
- Files: `specs/001-sms-scanning-to/README.md`

## Parallel execution groups (examples)
- Group A [P]: T004, T005, T006, T007 (models & migrations) can run together in separate PRs
- Group B [P]: T008, T010 (parsing rule loader and SMS service) are independent and can run in parallel
- Group C [P]: T012, T013 (prediction + feedback) can run in parallel after parsing pipeline is available

## Task agent command examples
- To run a task locally, use: `git checkout -b <task-branch> && <implement changes> && flutter test <test-path> && git add . && git commit -m "T###: summary"`
- Example (T005):
	- `git checkout -b feat/T005-transaction-model`
	- Create `lib/models/transaction.dart` and `test/unit/transaction_test.dart`
	- `flutter test test/unit/transaction_test.dart`
	- `git add . && git commit -m "T005: add Transaction model and validation"`

## Acceptance & Done criteria
- Every task must include tests (unit or widget) that initially fail and then pass after implementation.
- PRs should be small and scoped to 1–3 files where possible.
- Merge when CI passes and at least one reviewer approves.
