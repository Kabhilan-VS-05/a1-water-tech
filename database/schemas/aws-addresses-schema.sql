create table if not exists user_addresses (
  id bigserial primary key,
  user_id text not null,
  label text not null default '',
  full_name text not null default '',
  phone text not null default '',
  email text not null default '',
  city text not null default '',
  pincode text not null default '',
  address text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_addresses_user_created_at_idx
  on user_addresses (user_id, created_at desc);
