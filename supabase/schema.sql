create extension if not exists pgcrypto;

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user() cascade;
drop function if exists public.is_username_available(text) cascade;
drop function if exists public.request_registration(text, text) cascade;
drop function if exists public.approve_registration(bigint) cascade;
drop function if exists public.decline_registration(bigint) cascade;
drop function if exists public.set_profile_status(bigint, text) cascade;
drop function if exists public.submit_quiz(bigint, bigint, bigint, text, integer, jsonb) cascade;
drop function if exists public.find_question_integrity_issues() cascade;
drop function if exists public.player_of_week() cascade;

drop table if exists public.user_answers cascade;
drop table if exists public.quiz_attempts cascade;
drop table if exists public.questions cascade;
drop table if exists public.exam_sub_areas cascade;
drop table if exists public.exam_areas cascade;
drop table if exists public.exam_types cascade;
drop table if exists public.registration_requests cascade;
drop table if exists public.admin_activity_logs cascade;
drop table if exists public.court_maintenance cascade;
drop table if exists public.notifications cascade;
drop table if exists public.bookings cascade;
drop table if exists public.courts cascade;
drop table if exists public.profiles cascade;
drop table if exists public.app_settings cascade;
drop sequence if exists public.booking_reference_seq;

create sequence public.booking_reference_seq start 1;

create table public.app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

insert into public.app_settings (key, value)
values ('max_rental_hours', '4')
on conflict (key) do update set value = excluded.value;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  username text not null unique check (username ~ '^[a-z0-9._-]{3,32}$'),
  contact_number text,
  role text not null default 'customer' check (role in ('admin', 'customer')),
  profile_image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.courts (
  id uuid primary key default gen_random_uuid(),
  court_name text not null,
  court_number integer not null unique check (court_number between 1 and 3),
  hourly_rate numeric(10,2) not null default 250 check (hourly_rate > 0),
  status text not null default 'available' check (status in ('available', 'maintenance', 'inactive')),
  maintenance_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.courts (court_name, court_number, hourly_rate, status)
values
  ('Court 1', 1, 250, 'available'),
  ('Court 2', 2, 250, 'available'),
  ('Court 3', 3, 250, 'available')
on conflict (court_number) do update set
  court_name = excluded.court_name,
  hourly_rate = excluded.hourly_rate,
  updated_at = now();

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_reference text not null unique,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  court_id uuid not null references public.courts(id) on delete restrict,
  booking_date date not null,
  start_time time not null,
  end_time time not null,
  duration_hours integer not null check (duration_hours >= 1),
  hourly_rate numeric(10,2) not null default 250 check (hourly_rate > 0),
  total_amount numeric(10,2) not null check (total_amount >= 0),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'declined', 'active', 'completed', 'cancelled')),
  payment_proof_url text,
  payment_status text not null default 'pending'
    check (payment_status in ('pending', 'verified', 'rejected')),
  admin_note text,
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint booking_time_order check (end_time > start_time),
  constraint booking_total_matches_duration check (total_amount = duration_hours * hourly_rate)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null check (
    type in (
      'booking_submitted',
      'booking_approved',
      'booking_declined',
      'booking_reminder',
      'time_remaining',
      'booking_completed',
      'booking_cancelled',
      'admin_message'
    )
  ),
  is_read boolean not null default false,
  related_booking_id uuid references public.bookings(id) on delete cascade,
  dedupe_key text,
  created_at timestamptz not null default now()
);

create table public.admin_activity_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.profiles(id) on delete set null,
  action text not null,
  details text not null,
  related_booking_id uuid references public.bookings(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.court_maintenance (
  id uuid primary key default gen_random_uuid(),
  court_id uuid not null references public.courts(id) on delete cascade,
  start_datetime timestamptz not null,
  end_datetime timestamptz not null,
  reason text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint maintenance_time_order check (end_datetime > start_datetime)
);

create index profiles_role_idx on public.profiles(role);
create index profiles_username_idx on public.profiles(username);
create index courts_status_idx on public.courts(status);
create index bookings_customer_idx on public.bookings(customer_id);
create index bookings_court_date_idx on public.bookings(court_id, booking_date, start_time, end_time);
create index bookings_status_idx on public.bookings(status);
create index bookings_payment_status_idx on public.bookings(payment_status);
create index bookings_created_at_idx on public.bookings(created_at desc);
create index notifications_user_read_idx on public.notifications(user_id, is_read, created_at desc);
create index maintenance_court_time_idx on public.court_maintenance(court_id, start_datetime, end_datetime);
create index activity_logs_created_idx on public.admin_activity_logs(created_at desc);

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.profiles where id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  )
$$;

create or replace function public.max_rental_hours()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select greatest(1, coalesce((select value::integer from public.app_settings where key = 'max_rental_hours'), 4))
$$;

create or replace function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  with normalized as (
    select lower(trim(coalesce(p_username, ''))) as username
  )
  select username ~ '^[a-z0-9._-]{3,32}$'
    and not exists (
      select 1
      from public.profiles
      where profiles.username = normalized.username
    )
    and not exists (
      select 1
      from auth.users
      where lower(coalesce(raw_user_meta_data ->> 'username', '')) = normalized.username
        or lower(coalesce(email, '')) = 'apspicklezone+' || normalized.username || '@gmail.com'
    )
  from normalized
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

create trigger courts_touch_updated_at
  before update on public.courts
  for each row execute function public.touch_updated_at();

create trigger bookings_touch_updated_at
  before update on public.bookings
  for each row execute function public.touch_updated_at();

create or replace function public.next_booking_reference()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_year text := to_char(timezone('Asia/Manila', now()), 'YYYY');
  v_number bigint := nextval('public.booking_reference_seq');
begin
  return 'APZ-' || v_year || '-' || lpad(v_number::text, 5, '0');
end;
$$;

create or replace function public.local_booking_start(p_booking public.bookings)
returns timestamp
language sql
stable
as $$
  select p_booking.booking_date + p_booking.start_time
$$;

create or replace function public.local_booking_end(p_booking public.bookings)
returns timestamp
language sql
stable
as $$
  select p_booking.booking_date + p_booking.end_time
$$;

create or replace function public.notify_once(
  p_user_id uuid,
  p_title text,
  p_message text,
  p_type text,
  p_related_booking_id uuid default null,
  p_dedupe_key text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_dedupe_key is not null and exists (
    select 1
    from public.notifications
    where user_id = p_user_id
      and coalesce(related_booking_id::text, '') = coalesce(p_related_booking_id::text, '')
      and dedupe_key = p_dedupe_key
  ) then
    return;
  end if;

  insert into public.notifications (
    user_id, title, message, type, related_booking_id, dedupe_key
  )
  values (
    p_user_id, p_title, p_message, p_type, p_related_booking_id, p_dedupe_key
  );
end;
$$;

create or replace function public.notify_admins(
  p_title text,
  p_message text,
  p_type text,
  p_related_booking_id uuid default null,
  p_dedupe_key text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.profiles%rowtype;
begin
  for v_admin in select * from public.profiles where role = 'admin' loop
    perform public.notify_once(
      v_admin.id, p_title, p_message, p_type, p_related_booking_id, p_dedupe_key
    );
  end loop;
end;
$$;

create or replace function public.log_admin_action(
  p_action text,
  p_details text,
  p_related_booking_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.admin_activity_logs (
    admin_id, action, details, related_booking_id
  )
  values (
    public.current_profile_id(), p_action, p_details, p_related_booking_id
  );
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_full_name text := trim(coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  v_username text := lower(trim(coalesce(new.raw_user_meta_data ->> 'username', '')));
  v_contact text := trim(coalesce(new.raw_user_meta_data ->> 'contact_number', ''));
  v_first_user boolean;
begin
  if v_full_name = '' then
    v_full_name := coalesce(
      nullif(v_username, ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Player'
    );
  end if;
  if v_username = '' then
    v_username := lower(split_part(coalesce(new.email, new.id::text), '@', 1));
  end if;
  v_username := regexp_replace(v_username, '^apspicklezone\+', '');
  v_username := regexp_replace(v_username, '[^a-z0-9._-]', '_', 'g');
  if length(v_username) < 3 then
    v_username := left(v_username || '_user', 32);
  else
    v_username := left(v_username, 32);
  end if;
  if v_username !~ '^[a-z0-9._-]{3,32}$' then
    raise exception 'Username must use 3-32 lowercase letters, numbers, dots, dashes, or underscores.';
  end if;
  if exists (select 1 from public.profiles where username = v_username) then
    raise exception 'Username is already taken.';
  end if;
  v_first_user := not exists (select 1 from public.profiles);

  insert into public.profiles (
    id, full_name, username, contact_number, role
  )
  values (
    new.id,
    v_full_name,
    v_username,
    nullif(v_contact, ''),
    case when v_first_user then 'admin' else 'customer' end
  );

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.bypass_booking_guard', true) = 'on' then
    return new;
  end if;

  if public.is_admin() then
    return new;
  end if;

  if old.id <> new.id or old.username <> new.username or old.role <> new.role then
    raise exception 'Customers cannot change profile identity, username, or role.';
  end if;

  return new;
end;
$$;

create trigger profiles_guard_update
  before update on public.profiles
  for each row execute function public.guard_profile_update();

create or replace function public.validate_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_start timestamp := new.booking_date + new.start_time;
  v_end timestamp := new.booking_date + new.end_time;
  v_now timestamp := timezone('Asia/Manila', now());
  v_court public.courts%rowtype;
  v_max_hours integer := public.max_rental_hours();
begin
  if date_part('minute', new.start_time) <> 0
    or date_part('second', new.start_time) <> 0
    or date_part('minute', new.end_time) <> 0
    or date_part('second', new.end_time) <> 0 then
    raise exception 'Bookings must start and end on whole-hour time slots.';
  end if;

  if new.end_time <= new.start_time then
    raise exception 'Booking end time must be after start time.';
  end if;

  if mod(extract(epoch from (v_end - v_start))::integer, 3600) <> 0 then
    raise exception 'Booking duration must be measured in whole hours.';
  end if;

  new.duration_hours := extract(epoch from (v_end - v_start))::integer / 3600;
  if new.duration_hours < 1 then
    raise exception 'Minimum booking duration is 1 hour.';
  end if;
  if new.duration_hours > v_max_hours then
    raise exception 'Maximum booking duration is % hours.', v_max_hours;
  end if;

  select * into v_court from public.courts where id = new.court_id for update;
  if not found then
    raise exception 'Court not found.';
  end if;

  new.hourly_rate := v_court.hourly_rate;
  new.total_amount := new.duration_hours * new.hourly_rate;

  if new.status in ('pending', 'approved', 'active') and v_court.status <> 'available' then
    raise exception 'This court is currently unavailable.';
  end if;

  if tg_op = 'INSERT' and v_start <= v_now then
    raise exception 'Bookings cannot be created for past dates or times.';
  end if;

  if new.status in ('pending', 'approved', 'active') and exists (
    select 1
    from public.bookings b
    where b.id <> new.id
      and b.court_id = new.court_id
      and b.booking_date = new.booking_date
      and b.status in ('pending', 'approved', 'active')
      and b.start_time < new.end_time
      and new.start_time < b.end_time
  ) then
    raise exception 'This court already has a pending or approved booking for that time.';
  end if;

  if new.status in ('pending', 'approved', 'active') and exists (
    select 1
    from public.court_maintenance m
    where m.court_id = new.court_id
      and tstzrange(m.start_datetime, m.end_datetime, '[)') &&
          tstzrange(v_start at time zone 'Asia/Manila', v_end at time zone 'Asia/Manila', '[)')
  ) then
    raise exception 'This court is blocked for maintenance or an event.';
  end if;

  return new;
end;
$$;

create trigger bookings_validate
  before insert or update on public.bookings
  for each row execute function public.validate_booking();

create or replace function public.guard_booking_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_setting('app.bypass_booking_guard', true) = 'on' then
    return new;
  end if;

  if public.is_admin() then
    return new;
  end if;

  if old.customer_id <> auth.uid() then
    raise exception 'You can only update your own booking.';
  end if;

  if old.id <> new.id
    or old.booking_reference <> new.booking_reference
    or old.customer_id <> new.customer_id
    or old.court_id <> new.court_id
    or old.booking_date <> new.booking_date
    or old.start_time <> new.start_time
    or old.end_time <> new.end_time
    or old.duration_hours <> new.duration_hours
    or old.hourly_rate <> new.hourly_rate
    or old.total_amount <> new.total_amount
    or old.status <> new.status
    or old.payment_status <> new.payment_status
    or coalesce(old.admin_note, '') <> coalesce(new.admin_note, '')
    or coalesce(old.approved_by::text, '') <> coalesce(new.approved_by::text, '')
    or coalesce(old.approved_at::text, '') <> coalesce(new.approved_at::text, '') then
    raise exception 'Customers can only upload payment proof for their own booking.';
  end if;

  return new;
end;
$$;

create trigger bookings_guard_update
  before update on public.bookings
  for each row execute function public.guard_booking_update();

create or replace function public.create_booking(
  p_court_id uuid,
  p_booking_date date,
  p_start_time time,
  p_duration_hours integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid := public.current_profile_id();
  v_end_time time;
  v_booking_id uuid;
  v_reference text;
begin
  if v_profile_id is null then
    raise exception 'A signed-in profile is required.';
  end if;
  if p_duration_hours < 1 then
    raise exception 'Minimum booking duration is 1 hour.';
  end if;
  if p_duration_hours > public.max_rental_hours() then
    raise exception 'Maximum booking duration is % hours.', public.max_rental_hours();
  end if;

  v_end_time := p_start_time + make_interval(hours => p_duration_hours);
  v_reference := public.next_booking_reference();

  insert into public.bookings (
    booking_reference,
    customer_id,
    court_id,
    booking_date,
    start_time,
    end_time,
    duration_hours,
    hourly_rate,
    total_amount
  )
  values (
    v_reference,
    v_profile_id,
    p_court_id,
    p_booking_date,
    p_start_time,
    v_end_time,
    p_duration_hours,
    250,
    p_duration_hours * 250
  )
  returning id into v_booking_id;

  perform public.notify_once(
    v_profile_id,
    'Booking submitted',
    'Your booking request ' || v_reference || ' is pending payment verification.',
    'booking_submitted',
    v_booking_id,
    'booking_submitted'
  );

  perform public.notify_admins(
    'New booking request',
    'Booking ' || v_reference || ' is waiting for payment proof verification.',
    'booking_submitted',
    v_booking_id,
    'admin_booking_submitted'
  );

  return v_booking_id;
end;
$$;

create or replace function public.upload_payment_proof(
  p_booking_id uuid,
  p_payment_proof_url text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
begin
  perform set_config('app.bypass_booking_guard', 'on', true);

  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then
    raise exception 'Booking not found.';
  end if;
  if v_booking.customer_id <> auth.uid() and not public.is_admin() then
    raise exception 'You can only upload payment proof for your own booking.';
  end if;
  if v_booking.status <> 'pending' then
    raise exception 'Payment proof can only be uploaded for pending bookings.';
  end if;

  update public.bookings
  set payment_proof_url = p_payment_proof_url,
      payment_status = 'pending'
  where id = p_booking_id;

  perform public.notify_admins(
    'Payment proof uploaded',
    'Booking ' || v_booking.booking_reference || ' has payment proof ready for review.',
    'booking_submitted',
    p_booking_id,
    'payment_proof_uploaded'
  );
end;
$$;

create or replace function public.approve_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Administrator access is required.';
  end if;
  perform set_config('app.bypass_booking_guard', 'on', true);

  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then
    raise exception 'Booking not found.';
  end if;
  if v_booking.status <> 'pending' then
    raise exception 'Only pending bookings can be approved.';
  end if;
  if v_booking.payment_proof_url is null then
    raise exception 'Payment proof is required before approval.';
  end if;

  update public.bookings
  set status = 'approved',
      payment_status = 'verified',
      approved_by = public.current_profile_id(),
      approved_at = now(),
      admin_note = null
  where id = p_booking_id;

  perform public.notify_once(
    v_booking.customer_id,
    'Booking approved',
    'Your booking ' || v_booking.booking_reference || ' has been approved.',
    'booking_approved',
    p_booking_id,
    'booking_approved'
  );
  perform public.log_admin_action(
    'Booking approval',
    'Approved ' || v_booking.booking_reference || ' and verified payment proof.',
    p_booking_id
  );
end;
$$;

create or replace function public.decline_booking(
  p_booking_id uuid,
  p_admin_note text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Administrator access is required.';
  end if;
  perform set_config('app.bypass_booking_guard', 'on', true);
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then
    raise exception 'Booking not found.';
  end if;
  if v_booking.status not in ('pending', 'approved') then
    raise exception 'Only pending or approved bookings can be declined.';
  end if;

  update public.bookings
  set status = 'declined',
      payment_status = 'rejected',
      admin_note = nullif(trim(p_admin_note), '')
  where id = p_booking_id;

  perform public.notify_once(
    v_booking.customer_id,
    'Booking declined',
    'Your booking ' || v_booking.booking_reference || ' was declined. ' || coalesce(nullif(trim(p_admin_note), ''), ''),
    'booking_declined',
    p_booking_id,
    'booking_declined'
  );
  perform public.log_admin_action(
    'Booking decline',
    'Declined ' || v_booking.booking_reference || '. ' || coalesce(nullif(trim(p_admin_note), ''), ''),
    p_booking_id
  );
end;
$$;

create or replace function public.cancel_booking(
  p_booking_id uuid,
  p_admin_note text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Administrator access is required.';
  end if;
  perform set_config('app.bypass_booking_guard', 'on', true);
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then
    raise exception 'Booking not found.';
  end if;
  if v_booking.status in ('completed', 'cancelled', 'declined') then
    raise exception 'This booking can no longer be cancelled.';
  end if;

  update public.bookings
  set status = 'cancelled',
      admin_note = nullif(trim(p_admin_note), '')
  where id = p_booking_id;

  perform public.notify_once(
    v_booking.customer_id,
    'Booking cancelled',
    'Your booking ' || v_booking.booking_reference || ' was cancelled. ' || coalesce(nullif(trim(p_admin_note), ''), ''),
    'booking_cancelled',
    p_booking_id,
    'booking_cancelled'
  );
  perform public.log_admin_action(
    'Booking cancellation',
    'Cancelled ' || v_booking.booking_reference || '. ' || coalesce(nullif(trim(p_admin_note), ''), ''),
    p_booking_id
  );
end;
$$;

create or replace function public.complete_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Administrator access is required.';
  end if;
  perform set_config('app.bypass_booking_guard', 'on', true);
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then
    raise exception 'Booking not found.';
  end if;
  if v_booking.status not in ('approved', 'active') then
    raise exception 'Only approved or active bookings can be completed.';
  end if;

  update public.bookings
  set status = 'completed'
  where id = p_booking_id;

  perform public.notify_once(
    v_booking.customer_id,
    'Rental completed',
    'Your rental for booking ' || v_booking.booking_reference || ' is finished.',
    'booking_completed',
    p_booking_id,
    'booking_completed'
  );
  perform public.log_admin_action(
    'Booking completion',
    'Marked ' || v_booking.booking_reference || ' as completed.',
    p_booking_id
  );
end;
$$;

create or replace function public.set_court_status(
  p_court_id uuid,
  p_status text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_court public.courts%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Administrator access is required.';
  end if;
  if p_status not in ('available', 'maintenance', 'inactive') then
    raise exception 'Invalid court status.';
  end if;

  select * into v_court from public.courts where id = p_court_id for update;
  if not found then
    raise exception 'Court not found.';
  end if;

  update public.courts
  set status = p_status,
      maintenance_note = case when p_status = 'available' then null else nullif(trim(p_note), '') end
  where id = p_court_id;

  perform public.log_admin_action(
    'Court status change',
    'Set ' || v_court.court_name || ' to ' || p_status || '. ' || coalesce(nullif(trim(p_note), ''), ''),
    null
  );
end;
$$;

create or replace function public.schedule_court_maintenance(
  p_court_id uuid,
  p_start_datetime timestamptz,
  p_end_datetime timestamptz,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_start_local timestamp := timezone('Asia/Manila', p_start_datetime);
  v_end_local timestamp := timezone('Asia/Manila', p_end_datetime);
  v_court public.courts%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Administrator access is required.';
  end if;
  if p_end_datetime <= p_start_datetime then
    raise exception 'Maintenance end time must be after start time.';
  end if;
  if trim(coalesce(p_reason, '')) = '' then
    raise exception 'Maintenance reason is required.';
  end if;
  select * into v_court from public.courts where id = p_court_id;
  if not found then
    raise exception 'Court not found.';
  end if;

  if exists (
    select 1
    from public.bookings b
    where b.court_id = p_court_id
      and b.status in ('pending', 'approved', 'active')
      and tstzrange(p_start_datetime, p_end_datetime, '[)') &&
          tstzrange(
            (b.booking_date + b.start_time) at time zone 'Asia/Manila',
            (b.booking_date + b.end_time) at time zone 'Asia/Manila',
            '[)'
          )
  ) then
    raise exception 'Maintenance overlaps an existing pending or approved booking.';
  end if;

  insert into public.court_maintenance (
    court_id, start_datetime, end_datetime, reason, created_by
  )
  values (
    p_court_id, p_start_datetime, p_end_datetime, trim(p_reason), public.current_profile_id()
  )
  returning id into v_id;

  perform public.log_admin_action(
    'Court maintenance scheduled',
    'Scheduled ' || v_court.court_name || ' from ' || v_start_local || ' to ' || v_end_local || '.',
    null
  );
  return v_id;
end;
$$;

create or replace function public.refresh_booking_statuses()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamp := timezone('Asia/Manila', now());
  v_booking public.bookings%rowtype;
begin
  perform set_config('app.bypass_booking_guard', 'on', true);

  for v_booking in
    select * from public.bookings
    where status = 'approved'
      and public.local_booking_start(bookings) <= v_now
      and public.local_booking_end(bookings) > v_now
  loop
    update public.bookings set status = 'active' where id = v_booking.id;
    perform public.notify_once(
      v_booking.customer_id,
      'Rental started',
      'Your rental for booking ' || v_booking.booking_reference || ' is now active.',
      'booking_reminder',
      v_booking.id,
      'rental_started'
    );
  end loop;

  for v_booking in
    select * from public.bookings
    where status = 'active'
      and public.local_booking_end(bookings) <= v_now
  loop
    update public.bookings set status = 'completed' where id = v_booking.id;
    perform public.notify_once(
      v_booking.customer_id,
      'Rental finished',
      'Your rental for booking ' || v_booking.booking_reference || ' is finished.',
      'booking_completed',
      v_booking.id,
      'rental_finished'
    );
  end loop;

  for v_booking in
    select * from public.bookings
    where status = 'approved'
      and public.local_booking_start(bookings) > v_now
      and public.local_booking_start(bookings) <= v_now + interval '15 minutes'
  loop
    perform public.notify_once(
      v_booking.customer_id,
      'Rental starts soon',
      'Your rental for booking ' || v_booking.booking_reference || ' starts soon.',
      'booking_reminder',
      v_booking.id,
      'starts_soon'
    );
  end loop;

  for v_booking in
    select * from public.bookings
    where status = 'active'
      and public.local_booking_end(bookings) > v_now
      and public.local_booking_end(bookings) <= v_now + interval '30 minutes'
  loop
    perform public.notify_once(
      v_booking.customer_id,
      '30 minutes remaining',
      'Your rental for booking ' || v_booking.booking_reference || ' has 30 minutes remaining.',
      'time_remaining',
      v_booking.id,
      'remaining_30'
    );
  end loop;

  for v_booking in
    select * from public.bookings
    where status = 'active'
      and public.local_booking_end(bookings) > v_now
      and public.local_booking_end(bookings) <= v_now + interval '10 minutes'
  loop
    perform public.notify_once(
      v_booking.customer_id,
      '10 minutes remaining',
      'Your rental for booking ' || v_booking.booking_reference || ' has 10 minutes remaining.',
      'time_remaining',
      v_booking.id,
      'remaining_10'
    );
  end loop;
end;
$$;

create or replace function public.player_of_week()
returns table (
  customer_id uuid,
  full_name text,
  username text,
  booking_count integer,
  total_hours integer,
  total_amount numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with bounds as (
    select date_trunc('week', timezone('Asia/Manila', now()))::timestamp as week_start
  )
  select
    profiles.id as customer_id,
    profiles.full_name,
    profiles.username,
    count(bookings.id)::integer as booking_count,
    coalesce(sum(bookings.duration_hours), 0)::integer as total_hours,
    coalesce(sum(bookings.total_amount), 0)::numeric as total_amount
  from public.bookings
  join public.profiles on profiles.id = bookings.customer_id
  cross join bounds
  where bookings.status = 'completed'
    and (bookings.booking_date + bookings.start_time) >= bounds.week_start
    and (bookings.booking_date + bookings.start_time) < bounds.week_start + interval '7 days'
  group by profiles.id, profiles.full_name, profiles.username
  order by total_hours desc, total_amount desc, booking_count desc, profiles.full_name
  limit 10
$$;

alter table public.app_settings enable row level security;
alter table public.profiles enable row level security;
alter table public.courts enable row level security;
alter table public.bookings enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_activity_logs enable row level security;
alter table public.court_maintenance enable row level security;

create policy app_settings_admin_select on public.app_settings
  for select to authenticated using (public.is_admin());
create policy app_settings_admin_update on public.app_settings
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy profiles_select_own_or_admin on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());
create policy profiles_update_own_or_admin on public.profiles
  for update to authenticated using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

create policy courts_select_authenticated on public.courts
  for select to authenticated using (true);
create policy courts_admin_update on public.courts
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy bookings_select_own_or_admin on public.bookings
  for select to authenticated using (customer_id = auth.uid() or public.is_admin());
create policy bookings_insert_own_pending on public.bookings
  for insert to authenticated with check (customer_id = auth.uid() and status = 'pending');
create policy bookings_customer_payment_update on public.bookings
  for update to authenticated using (customer_id = auth.uid() or public.is_admin())
  with check (customer_id = auth.uid() or public.is_admin());
create policy bookings_admin_delete on public.bookings
  for delete to authenticated using (public.is_admin());

create policy notifications_select_own_or_admin on public.notifications
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy notifications_update_own_or_admin on public.notifications
  for update to authenticated using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());
create policy notifications_admin_insert on public.notifications
  for insert to authenticated with check (public.is_admin());

create policy activity_logs_admin_select on public.admin_activity_logs
  for select to authenticated using (public.is_admin());
create policy activity_logs_admin_insert on public.admin_activity_logs
  for insert to authenticated with check (public.is_admin());

create policy maintenance_select_authenticated on public.court_maintenance
  for select to authenticated using (true);
create policy maintenance_admin_insert on public.court_maintenance
  for insert to authenticated with check (public.is_admin());
create policy maintenance_admin_update on public.court_maintenance
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy maintenance_admin_delete on public.court_maintenance
  for delete to authenticated using (public.is_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('payment-proofs', 'payment-proofs', false, 8388608, array['image/jpeg', 'image/png', 'application/pdf']),
  ('profile-images', 'profile-images', false, 15728640, array['image/jpeg', 'image/png'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists payment_proofs_select on storage.objects;
drop policy if exists payment_proofs_insert on storage.objects;
drop policy if exists payment_proofs_update on storage.objects;
drop policy if exists profile_images_select on storage.objects;
drop policy if exists profile_images_insert on storage.objects;
drop policy if exists profile_images_update on storage.objects;

create policy payment_proofs_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy payment_proofs_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'payment-proofs'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy payment_proofs_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'payment-proofs'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  )
  with check (
    bucket_id = 'payment-proofs'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy profile_images_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'profile-images'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy profile_images_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy profile_images_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to authenticated;
grant usage, select on sequence public.booking_reference_seq to authenticated;
grant execute on all functions in schema public to authenticated;
grant execute on function public.is_username_available(text) to anon, authenticated;
