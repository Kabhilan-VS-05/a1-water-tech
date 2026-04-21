-- AWS admin schema additions for the Flutter billing/admin app.
-- Run this after the existing readonly/orders/bookings/feedback schemas.

create table if not exists admins (
  id bigserial primary key,
  cognito_sub text not null default '' unique,
  email text not null unique,
  display_name text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists bills (
  id bigserial primary key,
  bill_number text not null unique,
  source text not null default 'manual',
  source_order_doc_id text not null default '',
  source_order_id text not null default '',
  user_id text not null default '',
  customer jsonb not null default '{}'::jsonb,
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(12, 2) not null default 0,
  billing jsonb not null default '{}'::jsonb,
  total numeric(12, 2) not null default 0,
  status text not null default 'confirmed',
  generated_by text not null default '',
  updated_by text not null default '',
  company_name text not null default 'A1 Water Tech',
  support_phone text not null default '',
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists bills_created_at_idx
  on bills (created_at desc);

create index if not exists bills_user_created_at_idx
  on bills (user_id, created_at desc);

alter table orders
  add column if not exists confirmed_at timestamptz,
  add column if not exists bill_number text not null default '',
  add column if not exists bill_id text not null default '',
  add column if not exists billed_at timestamptz;

alter table bookings
  add column if not exists confirmed_at timestamptz;

alter table feedback
  add column if not exists order_id text not null default '',
  add column if not exists admin_response text not null default '',
  add column if not exists updated_by text not null default '',
  add column if not exists responded_by text not null default '',
  add column if not exists created_by text not null default '',
  add column if not exists responded_at timestamptz,
  add column if not exists resolved_at timestamptz;
