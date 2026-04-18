create table if not exists cart_items (
  user_id text not null,
  product_id text not null,
  qty integer not null check (qty > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create index if not exists cart_items_user_updated_at_idx
  on cart_items (user_id, updated_at desc);
