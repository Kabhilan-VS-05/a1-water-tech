insert into admins (
  email,
  display_name,
  is_active
)
values (
  'techawater@gmail.com',
  'A1 Water Tech Admin',
  true
)
on conflict (email) do update
set
  display_name = excluded.display_name,
  is_active = true,
  updated_at = now();
