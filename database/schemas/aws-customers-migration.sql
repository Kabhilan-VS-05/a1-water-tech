-- Migration script to create the customers table in PostgreSQL for walk-in/manual customers
CREATE TABLE IF NOT EXISTS customers (
  id text PRIMARY KEY,
  name text NOT NULL,
  phone text UNIQUE,
  address text,
  email text,
  source text NOT NULL DEFAULT 'manual',
  total_visits integer NOT NULL DEFAULT 0,
  total_spent numeric(12, 2) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS customers_phone_idx ON customers (phone);
