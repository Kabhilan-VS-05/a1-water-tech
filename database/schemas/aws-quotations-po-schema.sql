-- AWS schema additions for Quotations and Purchase Orders.
-- Run this to create the backend Postgres tables.

create table if not exists quotations (
  id bigserial primary key,
  quotation_number text not null unique,
  customer_id text,
  customer_name text not null,
  customer_phone text,
  customer_address text,
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(12, 2) not null default 0,
  gst_amount numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  status text not null default 'draft',
  valid_until timestamptz not null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists purchase_orders (
  id bigserial primary key,
  po_number text not null unique,
  customer_id text,
  customer_name text not null,
  customer_phone text,
  billing_address jsonb not null default '{}'::jsonb,
  shipping_address jsonb not null default '{}'::jsonb,
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(12, 2) not null default 0,
  gst_amount numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  delivery_date timestamptz,
  payment_terms text,
  notes text,
  status text not null default 'draft',
  quotation_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists quotations_created_at_idx on quotations (created_at desc);
create index if not exists purchase_orders_created_at_idx on purchase_orders (created_at desc);
