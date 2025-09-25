# Data Model: SMS scanning & expenses

## Entities

1. Transaction
   - id: string (UUID)
   - transaction_id: string|null (bank-provided id when available)
   - date: ISO 8601 date/time
   - amount: decimal (positive value)
   - type: enum { debit, credit }
   - merchant: string|null
   - raw_text: string
   - inferred_category: string|null
   - user_category: string|null
   - status: enum { tentative, confirmed }
   - source: enum { sms, manual }
   - notes: string|null
   - created_at: ISO 8601
   - updated_at: ISO 8601

2. Income
   - id: string (UUID)
   - name: string
   - amount: decimal
   - recurrence: enum { monthly, one-time }
   - next_date: ISO 8601
   - notes: string|null
   - created_at: ISO 8601
   - updated_at: ISO 8601

3. UserSettings
   - id: string (single row)
   - google_drive_backup_enabled: boolean
   - backup_file_id: string|null
   - last_sync_at: ISO 8601|null
   - sms_parsing_preferences: json (curated patterns + enabled banks)
   - prediction_feedback_enabled: boolean

## Indexes & Constraints
- Index transactions on date, amount, merchant for quick duplicate search
- Unique constraint: id (primary key)

## Validation Rules
- amount > 0
- date must be a valid ISO 8601 date
- status transitions: tentative -> confirmed only via user action or validated parsing
