create table if not exists feedback (
  id bigserial primary key,
  customer_name text not null,
  phone text not null,
  email text not null default '',
  message text not null,
  source text not null default 'website_contact',
  status text not null default 'open',
  rating integer not null default 0 check (rating between 0 and 5),
  user_id text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists feedback_status_created_at_idx
  on feedback (status, created_at desc);
