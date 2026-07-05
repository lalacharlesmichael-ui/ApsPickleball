begin;

do $$
declare
  v_promoted_count integer;
begin
  perform set_config('app.bypass_booking_guard', 'on', true);

  update public.profiles
  set role = 'admin',
      updated_at = now()
  where username = 'khel'
    and role <> 'admin';

  get diagnostics v_promoted_count = row_count;

  if v_promoted_count = 0 then
    if exists (
      select 1
      from public.profiles
      where username = 'khel'
        and role = 'admin'
    ) then
      raise notice 'Profile "khel" is already an admin.';
    else
      raise exception 'No profile found with username "khel". Register that user first, then run this script again.';
    end if;
  end if;
end;
$$;

commit;

select id, username, role, updated_at
from public.profiles
where username = 'khel';
