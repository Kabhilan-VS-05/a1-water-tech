create table if not exists bookings (
  id bigserial primary key,
  user_id text not null,
  service_id text not null,
  service_name text not null,
  booking_date date not null,
  time_slot text not null,
  address_id text not null,
  address_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'scheduled',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bookings_user_created_at_idx
  on bookings (user_id, created_at desc);

create index if not exists bookings_status_date_idx
  on bookings (status, booking_date asc);
