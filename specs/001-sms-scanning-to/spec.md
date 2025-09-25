# Feature Specification: SMS scanning, category prediction, income & dashboard

**Feature Branch**: `001-sms-scanning-to`
**Created**: 2025-09-25
**Status**: Draft
**Input**: User description: "SMS scanning to automatically capture debit and credit transactions from bank messages; category prediction with manual override; income tracking including recurring monthly inflows; manual expense entry; dashboard showing current month expenses with charts, category breakdown and trends; daily end-of-day sync to a Google Drive Excel sheet for backup and analysis; personal use only (not published)"

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a single, personal user, I want the app to automatically extract expenses and incomes from my bank SMS messages so that I can see categorized transactions, add or correct entries manually, track monthly income (including recurring payments), view a dashboard of my current month's spending with charts and trends, and have a daily backup exported to a Google Drive Excel sheet.

### Acceptance Scenarios
1. **Given** the user has received bank SMS messages on their phone, **When** the app scans SMS, **Then** debit and credit transactions are detected and added as tentative transactions with parsed fields (amount, date, merchant/bank text, inferred type).

2. **Given** an extracted tentative transaction with an inferred category, **When** the user reviews it, **Then** they can accept the predicted category or manually change it and the correction updates the transaction and trains/records feedback for future predictions.

3. **Given** the user wants to record income, **When** they add a recurring monthly income (e.g., salary), **Then** the system records it and includes it in monthly totals and trend charts.

4. **Given** a transaction not captured via SMS, **When** the user manually creates an expense, **Then** the transaction is saved with the chosen category and appears in the dashboard and sync.

5. **Given** the end of day, **When** the daily sync runs, **Then** all transactions for that day are appended to a Google Drive Excel file (backup) without duplications and with a summary row for that day.

6. **Given** the user opens the dashboard, **When** it's the current month, **Then** show total expenses, income, category breakdown (pie or bar), daily spending trend (line), and top 5 merchants by spend.

### Edge Cases
- SMS messages with multiple transactions in one message: system should attempt to split and create multiple tentative transactions; if ambiguous, mark for manual review.
- Missed SMS (user deletes or provider blocks access): allow manual entry and an import fallback.
- Duplicate transactions (same amount, date, merchant): use heuristics to detect probable duplicates; require manual confirmation for ambiguous duplicates.
- Connectivity failure during daily sync: retry with exponential backoff; record last successful sync timestamp and show sync status to user.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST scan device SMS inbox for incoming bank/transaction messages and extract candidate transactions (amount, date, raw text, inferred merchant) as tentative records.
- **FR-002**: System MUST parse common bank SMS formats for debit and credit notices and support a way to add parsing rules for additional banks.
- **FR-003**: System MUST predict a category for each tentative transaction and surface the predicted category to the user.
- **FR-004**: Users MUST be able to manually override or correct the category for any transaction; corrections are stored as feedback for improving predictions.
- **FR-005**: System MUST allow users to add recurring income entries (monthly) and treat them as income items in summaries and charts.
- **FR-006**: System MUST allow manual entry of expenses with fields: date, amount, merchant/description, category, notes.
- **FR-007**: System MUST present a dashboard that defaults to the current month showing: total expenses, total income, net balance, category breakdown, daily spending trend, and top merchants.
- **FR-008**: System MUST perform a daily end-of-day export that appends the day's transactions to a Google Drive-hosted Excel file; export must avoid duplicate rows and include a timestamp and summary row.
- **FR-009**: System MUST allow the user to trigger manual sync/export and view last successful sync status and logs.
- **FR-010**: System MUST keep all data private to the user and explicitly note that the app is for personal use only and will not be published to app stores.

*Decisions (resolved)*:
- **FR-002 (parsing rules)**: Default will be a curated set of parsing rules maintained by the app. Additionally, provide an optional, opt-in "Custom parsing rules" area (power-user setting) that lets the single user add or disable simple parsing patterns. Custom rules are stored locally and do not affect other users (fits personal-use scope).
- **FR-008 (Google Drive export)**: Primary backup format will be a single Excel workbook (.xlsx) stored in the user's Google Drive. The daily export appends rows to a single sheet with these columns: transaction_id, date, amount, type (debit/credit), merchant, inferred_category, user_category, source (sms/manual), notes, created_at, updated_at, export_timestamp. CSV export will be supported as an alternative manual/export option. The app requires the user to sign in to their Google account and grant Drive access; the spec records a single backup file reference in user settings.

## Assumptions (best guesses applied)

- The app is strictly single-user (no multi-user sharing or server-side multi-tenant sync). All custom parsing rules and settings are stored locally on the device.
- Daily export runs once per local-device day (user's timezone) shortly after the user's typical bedtime; the app will expose a manual "Run backup now" action.
- Parsing rule updates provided by the app (curated set) will be delivered as app updates or as downloadable rule packs; custom rules are simple pattern-based entries editable by the user in a power-user screen.
- For Drive authentication the user will sign in via OAuth and grant the app access to a single file/folder; the app stores only a reference/id to the backup file in `UserSettings`.
- Deduplication on export uses transaction_id if available, otherwise heuristics on (date, amount, merchant, source) with a configurable tolerance window (e.g., 48 hours).

### Key Entities *(include if feature involves data)*
- **Transaction**: date, amount, type (debit/credit), merchant/raw_text, inferred_category, user_category, status (tentative/confirmed), source (sms/manual), created_at, updated_at
- **Income**: date, amount, recurrence (monthly), source, notes
- **UserSettings**: google_drive_backup_enabled, backup_file_id/path, last_sync_at, sms_parsing_preferences, prediction_feedback_enabled

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs) in requirements
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous where specified
- [x] Success criteria are measurable in acceptance scenarios
- [x] Scope is clearly bounded to personal use and daily Drive backup
- [x] Dependencies and assumptions identified where needed

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked and resolved
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed
