-- Read-only AWS migration schema for the first phase.
-- Phase 1 tables only:
--   products
--   services
--   announcements
--   business_settings
--   billing_settings

create table if not exists products (
  id text primary key,
  name text not null,
  category text not null,
  image_url text not null default '',
  price numeric(12, 2) not null default 0,
  rating numeric(3, 2) not null default 0,
  tag text not null default '',
  tds text not null default '',
  warranty text not null default '',
  description text not null default '',
  features jsonb not null default '[]'::jsonb,
  recommendation text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists services (
  id text primary key,
  name text not null,
  image_url text not null default '',
  price numeric(12, 2) not null default 0,
  duration text not null default '',
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists announcements (
  id text primary key,
  title text not null,
  message text not null,
  is_active boolean not null default true,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists business_settings (
  id smallint primary key check (id = 1),
  company_name text not null,
  support_phone text not null default '',
  support_email text not null default '',
  locality text not null default '',
  address_line1 text not null default '',
  address_line2 text not null default '',
  address_line3 text not null default '',
  gstin text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists billing_settings (
  id smallint primary key check (id = 1),
  company_name text not null default 'A1 Water Tech',
  support_phone text not null default '',
  invoice_prefix text not null default 'BILL',
  gst_rate numeric(5, 4) not null default 0,
  gst_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into business_settings (
  id,
  company_name,
  support_phone,
  support_email,
  locality,
  address_line1,
  address_line2,
  address_line3,
  gstin
)
values (
  1,
  'A1 Water Tech',
  '+91 8778308119',
  'thinakarans12345@gmail.com',
  'Gobichettipalayam, Tamil Nadu',
  'G.K.M Gowtham Complex, Opp. HP Bunk',
  'Sathy-Athani Main Road, Kalipatti',
  'Gobichettipalayam - 638505',
  '33CWHPH8901N1Z6'
)
on conflict (id) do nothing;

insert into billing_settings (
  id,
  company_name,
  support_phone,
  invoice_prefix,
  gst_rate,
  gst_enabled
)
values (
  1,
  'A1 Water Tech',
  '',
  'BILL',
  0,
  false
)
on conflict (id) do nothing;

create table if not exists faqs (
  id serial primary key,
  q text not null,
  a text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into faqs (q, a)
values 
  ('Do you offer free water testing?', 'Yes. We provide a free in-home TDS and hardness test in select areas.'),
  ('How quickly can you install a purifier?', 'Most installations are scheduled within 24 hours after order confirmation.'),
  ('Is GST included in the listed price?', 'Yes. All listed prices include GST. The invoice will show the breakup.'),
  ('What payment methods are supported?', 'UPI, card, netbanking, and EMI options on select products.')
on conflict do nothing;
