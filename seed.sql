-- =====================================================================
-- ADB CREATIVE TEAM — Data awal (OPSIONAL)
-- Jalankan SETELAH schema.sql. Tidak ada kegiatan, karya, prestasi, atau
-- nama anggota fiktif yang dibuat. Konten nyata ditambahkan oleh admin.
-- =====================================================================

update public.profiles set
  tagline = coalesce(nullif(tagline, ''), 'Creative Community & Digital Documentation'),
  description = coalesce(nullif(description, ''), 'Wadah kreativitas dan dokumentasi digital ADB CREATIVE TEAM. Tambahkan profil resmi organisasi melalui dashboard admin.'),
  history = coalesce(nullif(history, ''), 'Sejarah ADB CREATIVE TEAM belum diisi. Silakan lengkapi melalui dashboard admin.'),
  vision = coalesce(nullif(vision, ''), 'Tambahkan visi resmi ADB CREATIVE TEAM melalui dashboard admin.'),
  mission = coalesce(nullif(mission, ''), 'Tambahkan misi resmi satu poin per baris melalui dashboard admin.'),
  goals = coalesce(nullif(goals, ''), 'Tambahkan tujuan organisasi satu poin per baris melalui dashboard admin.')
where id = 1;

insert into public.categories (name, type) values
  ('Dokumentasi Event', 'activity'),
  ('Workshop',          'activity'),
  ('Pelatihan',         'activity'),
  ('Kompetisi',         'activity'),
  ('Kunjungan',         'activity'),
  ('Desain Grafis',     'project'),
  ('Fotografi',         'project'),
  ('Videografi',        'project'),
  ('Editing Video',     'project'),
  ('Konten Digital',    'project')
on conflict (name, type) do nothing;
