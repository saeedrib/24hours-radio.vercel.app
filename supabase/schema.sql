-- 24HOURS RADIO database schema
-- Run this file in Supabase SQL Editor after creating the dedicated radio project.
create extension if not exists pgcrypto;

create table if not exists public.radio_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'listener' check (role in ('listener','dj','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.radio_programs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  presenter text not null default '',
  start_time text not null default '',
  end_time text not null default '',
  description text not null default '',
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.radio_presenters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  show_name text not null default '',
  bio text not null default '',
  photo_url text not null default '',
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.radio_news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text not null default '',
  body text not null default '',
  author_id uuid references auth.users(id) on delete set null,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.radio_podcasts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  audio_url text not null,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.radio_settings (
  setting_key text primary key,
  setting_value text not null default '',
  updated_at timestamptz not null default now()
);

create or replace function public.radio_is_staff()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.radio_profiles p
    where p.user_id = (select auth.uid()) and p.role in ('admin','dj')
  );
$$;

create or replace function public.radio_is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.radio_profiles p
    where p.user_id = (select auth.uid()) and p.role = 'admin'
  );
$$;

alter table public.radio_profiles enable row level security;
alter table public.radio_programs enable row level security;
alter table public.radio_presenters enable row level security;
alter table public.radio_news enable row level security;
alter table public.radio_podcasts enable row level security;
alter table public.radio_settings enable row level security;

drop policy if exists "Users read own radio profile" on public.radio_profiles;
create policy "Users read own radio profile" on public.radio_profiles for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "Admins manage radio profiles" on public.radio_profiles;
create policy "Admins manage radio profiles" on public.radio_profiles for all to authenticated using ((select public.radio_is_admin())) with check ((select public.radio_is_admin()));

drop policy if exists "Public read published programs" on public.radio_programs;
create policy "Public read published programs" on public.radio_programs for select to anon, authenticated using (is_published or (select public.radio_is_staff()));
drop policy if exists "Staff manage programs" on public.radio_programs;
create policy "Staff manage programs" on public.radio_programs for all to authenticated using ((select public.radio_is_staff())) with check ((select public.radio_is_staff()));

drop policy if exists "Public read published presenters" on public.radio_presenters;
create policy "Public read published presenters" on public.radio_presenters for select to anon, authenticated using (is_published or (select public.radio_is_staff()));
drop policy if exists "Staff manage presenters" on public.radio_presenters;
create policy "Staff manage presenters" on public.radio_presenters for all to authenticated using ((select public.radio_is_staff())) with check ((select public.radio_is_staff()));

drop policy if exists "Public read published news" on public.radio_news;
create policy "Public read published news" on public.radio_news for select to anon, authenticated using (is_published or (select public.radio_is_staff()));
drop policy if exists "Staff manage news" on public.radio_news;
create policy "Staff manage news" on public.radio_news for all to authenticated using ((select public.radio_is_staff())) with check ((select public.radio_is_staff()));

drop policy if exists "Public read published podcasts" on public.radio_podcasts;
create policy "Public read published podcasts" on public.radio_podcasts for select to anon, authenticated using (is_published or (select public.radio_is_staff()));
drop policy if exists "Staff manage podcasts" on public.radio_podcasts;
create policy "Staff manage podcasts" on public.radio_podcasts for all to authenticated using ((select public.radio_is_staff())) with check ((select public.radio_is_staff()));

drop policy if exists "Public read live settings" on public.radio_settings;
create policy "Public read live settings" on public.radio_settings for select to anon, authenticated using (setting_key in ('stream_url','station_name','whatsapp'));
drop policy if exists "Admins manage settings" on public.radio_settings;
create policy "Admins manage settings" on public.radio_settings for all to authenticated using ((select public.radio_is_admin())) with check ((select public.radio_is_admin()));

grant select on public.radio_programs, public.radio_presenters, public.radio_news, public.radio_podcasts, public.radio_settings to anon, authenticated;
grant all on public.radio_programs, public.radio_presenters, public.radio_news, public.radio_podcasts, public.radio_settings to authenticated;
grant select, update on public.radio_profiles to authenticated;
grant execute on function public.radio_is_staff(), public.radio_is_admin() to authenticated;

-- IMPORTANT: After creating your first account, promote it manually in SQL Editor:
-- update public.radio_profiles set role='admin' where user_id=(select id from auth.users where email='YOUR-EMAIL');
-- Add DJ accounts similarly with role='dj'. Never allow public signup to choose admin/DJ role.

-- Create a listener profile automatically for every new Auth account.
create or replace function public.radio_handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.radio_profiles(user_id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name',''), 'listener')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_radio on auth.users;
create trigger on_auth_user_created_radio
after insert on auth.users
for each row execute procedure public.radio_handle_new_user();

-- Only an existing Admin can change a user's role. Never trust a role sent by signup metadata.
create or replace function public.radio_admin_set_role(target_email text, target_role text)
returns void language plpgsql security definer set search_path = ''
as $$
declare target_id uuid;
begin
  if not public.radio_is_admin() then
    raise exception 'Only radio administrators can assign staff roles';
  end if;
  if target_role not in ('listener','dj','admin') then
    raise exception 'Invalid role';
  end if;
  select id into target_id from auth.users where lower(email) = lower(trim(target_email)) limit 1;
  if target_id is null then
    raise exception 'No Auth account found for that email';
  end if;
  insert into public.radio_profiles(user_id, display_name, role)
  values (target_id, '', target_role)
  on conflict (user_id) do update set role = excluded.role;
end;
$$;
revoke all on function public.radio_admin_set_role(text,text) from public, anon;
grant execute on function public.radio_admin_set_role(text,text) to authenticated;
