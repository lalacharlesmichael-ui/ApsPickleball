-- Run this once in the Supabase SQL Editor for existing installations.
-- It adds admin-managed public slideshow images for user-facing app screens.

create extension if not exists pgcrypto;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.interface_backgrounds (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  storage_path text not null,
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.interface_backgrounds
  add column if not exists title text not null default 'Background',
  add column if not exists storage_path text,
  add column if not exists is_active boolean not null default true,
  add column if not exists display_order integer not null default 0,
  add column if not exists created_by uuid references public.profiles(id) on delete set null,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.interface_backgrounds
  alter column title drop default;

create unique index if not exists interface_backgrounds_storage_path_idx
  on public.interface_backgrounds(storage_path);

create index if not exists interface_backgrounds_active_idx
  on public.interface_backgrounds(is_active, display_order, created_at desc);

drop trigger if exists interface_backgrounds_touch_updated_at
  on public.interface_backgrounds;

create trigger interface_backgrounds_touch_updated_at
  before update on public.interface_backgrounds
  for each row execute function public.touch_updated_at();

alter table public.interface_backgrounds enable row level security;

drop policy if exists interface_backgrounds_select_public_active
  on public.interface_backgrounds;
drop policy if exists interface_backgrounds_admin_insert
  on public.interface_backgrounds;
drop policy if exists interface_backgrounds_admin_update
  on public.interface_backgrounds;
drop policy if exists interface_backgrounds_admin_delete
  on public.interface_backgrounds;

create policy interface_backgrounds_select_public_active
  on public.interface_backgrounds
  for select to anon, authenticated
  using (is_active or public.is_admin());

create policy interface_backgrounds_admin_insert
  on public.interface_backgrounds
  for insert to authenticated
  with check (public.is_admin());

create policy interface_backgrounds_admin_update
  on public.interface_backgrounds
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy interface_backgrounds_admin_delete
  on public.interface_backgrounds
  for delete to authenticated
  using (public.is_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('interface-backgrounds', 'interface-backgrounds', true, 15728640, array['image/jpeg', 'image/png'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists interface_backgrounds_select on storage.objects;
drop policy if exists interface_backgrounds_insert on storage.objects;
drop policy if exists interface_backgrounds_update on storage.objects;
drop policy if exists interface_backgrounds_delete on storage.objects;

create policy interface_backgrounds_select on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'interface-backgrounds');

create policy interface_backgrounds_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'interface-backgrounds' and public.is_admin());

create policy interface_backgrounds_update on storage.objects
  for update to authenticated
  using (bucket_id = 'interface-backgrounds' and public.is_admin())
  with check (bucket_id = 'interface-backgrounds' and public.is_admin());

create policy interface_backgrounds_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'interface-backgrounds' and public.is_admin());

grant select on public.interface_backgrounds to anon;
grant all on public.interface_backgrounds to authenticated;
