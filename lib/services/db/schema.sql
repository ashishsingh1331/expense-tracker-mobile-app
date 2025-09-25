-- Database schema for expense tracker

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id TEXT UNIQUE,  -- From bank/provider if available
  date TEXT NOT NULL,         -- ISO8601 format
  amount REAL NOT NULL,       -- Stored as positive for expenses
  merchant TEXT NOT NULL,     -- Store name/merchant name
  category TEXT,             -- User categorization
  notes TEXT,
  is_expense BOOLEAN NOT NULL DEFAULT 1,  -- 1 for expense, 0 for income
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for transactions
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_transactions_merchant ON transactions(merchant);

-- Income table for recurring entries
CREATE TABLE IF NOT EXISTS income (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  recurrence TEXT NOT NULL,  -- monthly, quarterly, annual
  start_date TEXT NOT NULL,  -- ISO8601 format
  end_date TEXT,            -- Optional end date
  category TEXT,            -- Income category
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- User settings table
CREATE TABLE IF NOT EXISTS user_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index for settings lookup
CREATE INDEX idx_settings_key ON user_settings(key);
