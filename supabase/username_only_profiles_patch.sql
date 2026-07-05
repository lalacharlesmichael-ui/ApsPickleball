alter table public.profiles
add column if not exists username text;

with candidates as (
  select
    p.id,
    regexp_replace(
      regexp_replace(
        lower(
          coalesce(
            nullif(trim(p.username), ''),
            nullif(trim(u.raw_user_meta_data ->> 'username'), ''),
            split_part(coalesce(u.email, p.id::text), '@', 1)
          )
        ),
        '^apspicklezone\+',
        ''
      ),
      '[^a-z0-9._-]',
      '_',
      'g'
    ) as candidate
  from public.profiles p
  left join auth.users u on u.id = p.id
),
bases as (
  select
    id,
    case
      when length(candidate) >= 3 then left(candidate, 28)
      else left(candidate || '_user', 28)
    end as base_username
  from candidates
),
numbered as (
  select
    id,
    base_username,
    row_number() over (partition by base_username order by id) as duplicate_number
  from bases
)
update public.profiles p
set username = case
  when numbered.duplicate_number = 1 then left(numbered.base_username, 32)
  else left(
    numbered.base_username,
    greatest(1, 31 - length(numbered.duplicate_number::text))
  ) || '_' || numbered.duplicate_number
end
from numbered
where p.id = numbered.id;

alter table public.profiles
alter column username set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_username_format'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
    add constraint profiles_username_format
    check (username ~ '^[a-z0-9._-]{3,32}$');
  end if;
end $$;

create unique index if not exists profiles_username_unique_idx
on public.profiles(username);

create index if not exists profiles_username_idx
on public.profiles(username);

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

drop trigger if exists on_auth_user_created on auth.users;

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
  v_role text;
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
  v_role := case when v_first_user then 'admin' else 'customer' end;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'email'
  ) then
    execute
      'insert into public.profiles (id, full_name, username, email, contact_number, role)
       values ($1, $2, $3, $4, $5, $6)'
    using new.id, v_full_name, v_username, coalesce(new.email, ''), nullif(v_contact, ''), v_role;
  else
    insert into public.profiles (
      id, full_name, username, contact_number, role
    )
    values (
      new.id,
      v_full_name,
      v_username,
      nullif(v_contact, ''),
      v_role
    );
  end if;

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

alter table public.profiles
drop column if exists email;

grant usage on schema public to anon, authenticated;
grant execute on function public.is_username_available(text) to anon, authenticated;
