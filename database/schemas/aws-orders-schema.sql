create table if not exists orders (
  id bigserial primary key,
  order_id text not null unique,
  user_id text not null,
  customer jsonb not null default '{}'::jsonb,
  address_id text not null default '',
  address_snapshot jsonb not null default '{}'::jsonb,
  items jsonb not null default '[]'::jsonb,
  billing jsonb not null default '{}'::jsonb,
  subtotal numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_user_created_at_idx
  on orders (user_id, created_at desc);
