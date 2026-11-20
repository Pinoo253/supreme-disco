-- =====================================================================
-- ADB CREATIVE TEAM — Skema database Supabase
-- Jalankan seluruh file ini di Supabase Dashboard -> SQL Editor.
-- Aman dijalankan berulang kali (idempotent).
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 1. Admin & fungsi otorisasi
-- ---------------------------------------------------------------------
-- Hanya user yang ada di tabel ini yang boleh mengubah konten.
create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------
-- 2. Tabel konten
-- ---------------------------------------------------------------------

-- Profil ekskul (satu baris saja, id = 1)
create table if not exists public.profiles (
  id             int primary key default 1 check (id = 1),
  name           text not null default 'ADB CREATIVE TEAM',
  tagline        text,
  description    text,
  history        text,
  vision         text,
  mission        text,   -- satu poin per baris
  goals          text,   -- satu poin per baris
  email          text,
  phone          text,
  address        text,
  instagram      text,
  youtube        text,
  tiktok         text,
  hero_image_url text,
  updated_at     timestamptz not null default now()
);

create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  type       text not null check (type in ('activity', 'project')),
  created_at timestamptz not null default now(),
  unique (name, type)
);

create table if not exists public.activities (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  date        date not null default current_date,
  location    text,
  category_id uuid references public.categories(id) on delete set null,
  description text,
  cover_url   text,
  video_url   text,
  created_at  timestamptz not null default now()
);

create table if not exists public.projects (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text,
  creator      text not null,
  published_at date not null default current_date,
  category_id  uuid references public.categories(id) on delete set null,
  image_url    text,
  video_url    text,
  link_url     text,
  is_featured  boolean not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists public.gallery (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  media_type  text not null default 'image' check (media_type in ('image', 'video')),
  url         text not null,
  activity_id uuid references public.activities(id) on delete set null,
  created_at  timestamptz not null default now()
);

create table if not exists public.achievements (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  competition     text not null,
  level           text not null,
  date            date not null default current_date,
  description     text,
  image_url       text,
  certificate_url text,
  created_at      timestamptz not null default now()
);

create table if not exists public.team_members (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  role       text not null,
  division   text,
  bio        text,
  photo_url  text,
  instagram  text,
  sort_order int not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists activities_date_idx   on public.activities (date desc);
create index if not exists projects_pub_idx      on public.projects (published_at desc);
create index if not exists gallery_activity_idx  on public.gallery (activity_id);
create index if not exists achievements_date_idx on public.achievements (date desc);

-- updated_at otomatis untuk profiles
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

insert into public.profiles (id, name, tagline)
values (1, 'ADB CREATIVE TEAM', 'Creative Community & Digital Documentation')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 3. Row Level Security
--    Pengunjung: hanya membaca. Admin: tambah / ubah / hapus.
-- ---------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'categories', 'activities', 'projects',
    'gallery', 'achievements', 'team_members'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists "public read"  on public.%I', t);
    execute format('drop policy if exists "admin insert" on public.%I', t);
    execute format('drop policy if exists "admin update" on public.%I', t);
    execute format('drop policy if exists "admin delete" on public.%I', t);

    execute format('create policy "public read" on public.%I for select to anon, authenticated using (true)', t);
    execute format('create policy "admin insert" on public.%I for insert to authenticated with check (public.is_admin())', t);
    execute format('create policy "admin update" on public.%I for update to authenticated using (public.is_admin()) with check (public.is_admin())', t);
    execute format('create policy "admin delete" on public.%I for delete to authenticated using (public.is_admin())', t);
  end loop;
end $$;

-- Tabel admins: user hanya boleh melihat barisnya sendiri.
-- Penambahan admin dilakukan lewat SQL Editor (lihat README).
alter table public.admins enable row level security;
drop policy if exists "read own admin row" on public.admins;
create policy "read own admin row" on public.admins
  for select to authenticated using (user_id = auth.uid());

-- Anggota nonaktif tidak dipublikasikan, tetapi tetap bisa dikelola admin.
drop policy if exists "public read" on public.team_members;
drop policy if exists "public read active members" on public.team_members;
drop policy if exists "authenticated read members" on public.team_members;
create policy "public read active members" on public.team_members
  for select to anon using (is_active = true);
create policy "authenticated read members" on public.team_members
  for select to authenticated using (is_active = true or public.is_admin());

-- Hak akses eksplisit agar tabel baru dari SQL Editor tetap dapat diakses
-- melalui API Supabase; RLS di atas tetap menjadi lapisan otorisasi utama.
grant usage on schema public to anon, authenticated;
grant select on public.profiles, public.categories, public.activities,
  public.projects, public.gallery, public.achievements, public.team_members
  to anon, authenticated;
grant insert, update, delete on public.profiles, public.categories,
  public.activities, public.projects, public.gallery, public.achievements,
  public.team_members to authenticated;
grant select on public.admins to authenticated;
grant execute on function public.is_admin() to anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. Saran & kritik publik
-- Pengunjung boleh mengirim pesan; hanya admin yang boleh membaca/menghapus.
-- ---------------------------------------------------------------------
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  email text check (email is null or char_length(email) <= 200),
  type text not null default 'Saran' check (type in ('Saran','Kritik','Apresiasi','Kolaborasi')),
  message text not null check (char_length(message) between 4 and 3000),
  created_at timestamptz not null default now()
);
create index if not exists feedback_created_idx on public.feedback (created_at desc);
alter table public.feedback enable row level security;
drop policy if exists "public submit feedback" on public.feedback;
drop policy if exists "admin read feedback" on public.feedback;
drop policy if exists "admin delete feedback" on public.feedback;
create policy "public submit feedback" on public.feedback for insert to anon, authenticated with check (true);
create policy "admin read feedback" on public.feedback for select to authenticated using (public.is_admin());
create policy "admin delete feedback" on public.feedback for delete to authenticated using (public.is_admin());
grant insert on public.feedback to anon, authenticated;
grant select, delete on public.feedback to authenticated;

-- ---------------------------------------------------------------------
-- 5. Storage (foto, video, dokumen)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'media', 'media', true, 52428800,  -- 50 MB (batas paket Free Supabase)
  array[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif',
    'video/mp4', 'video/webm', 'video/quicktime',
    'application/pdf'
  ]
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "media public read"  on storage.objects;
drop policy if exists "media admin insert" on storage.objects;
drop policy if exists "media admin update" on storage.objects;
drop policy if exists "media admin delete" on storage.objects;

create policy "media public read" on storage.objects
  for select to anon, authenticated using (bucket_id = 'media');
create policy "media admin insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'media' and public.is_admin());
create policy "media admin update" on storage.objects
  for update to authenticated using (bucket_id = 'media' and public.is_admin())
  with check (bucket_id = 'media' and public.is_admin());
create policy "media admin delete" on storage.objects
  for delete to authenticated using (bucket_id = 'media' and public.is_admin());

-- ADB CMS: six content categories
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins a where a.user_id = (select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('foto','video','berita','pencapaian','agenda','pengumuman')),
  title text not null check (char_length(title) between 1 and 180),
  description text not null default '' check (char_length(description) <= 500),
  body text not null default '',
  media_url text,
  media_type text check (media_type is null or media_type in ('image','video')),
  event_date timestamptz,
  location text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists content_items_category_created_idx on public.content_items(category, created_at desc);
create index if not exists content_items_published_idx on public.content_items(is_published, created_at desc);
alter table public.content_items enable row level security;
drop policy if exists "Public can read published CMS content" on public.content_items;
drop policy if exists "Admins can insert CMS content" on public.content_items;
drop policy if exists "Admins can update CMS content" on public.content_items;
drop policy if exists "Admins can delete CMS content" on public.content_items;
create policy "Public can read published CMS content" on public.content_items for select to anon, authenticated using (is_published = true or (select public.is_admin()));
create policy "Admins can insert CMS content" on public.content_items for insert to authenticated with check ((select public.is_admin()));
create policy "Admins can update CMS content" on public.content_items for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "Admins can delete CMS content" on public.content_items for delete to authenticated using ((select public.is_admin()));
grant select on public.content_items to anon, authenticated;
grant insert, update, delete on public.content_items to authenticated;

create or replace function public.content_items_set_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists content_items_updated_at on public.content_items;
create trigger content_items_updated_at before update on public.content_items for each row execute function public.content_items_set_updated_at();

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('media','media',true,52428800,array['image/jpeg','image/png','image/webp','image/gif','image/avif','video/mp4','video/webm','video/quicktime'])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "ADB media public read" on storage.objects;
drop policy if exists "ADB media admin upload" on storage.objects;
drop policy if exists "ADB media admin update" on storage.objects;
drop policy if exists "ADB media admin delete" on storage.objects;
create policy "ADB media public read" on storage.objects for select to anon, authenticated using (bucket_id='media');
create policy "ADB media admin upload" on storage.objects for insert to authenticated with check (bucket_id='media' and (select public.is_admin()));
create policy "ADB media admin update" on storage.objects for update to authenticated using (bucket_id='media' and (select public.is_admin())) with check (bucket_id='media' and (select public.is_admin()));
create policy "ADB media admin delete" on storage.objects for delete to authenticated using (bucket_id='media' and (select public.is_admin()));
