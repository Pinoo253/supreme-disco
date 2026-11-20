# ADB Creative Team — SMK Negeri 1 Adiwerna

Website portfolio ADB Creative Team dengan Supabase CMS. Identitas website menggunakan logo ADB Creative Team pada `assets/adb-creative-team-logo.webp`. Logo yang sama dipakai pada halaman publik, footer, dan dashboard admin.

## File penting

- `index.html`, `style.css`, `main.js`: website publik.
- `admin.html`, `admin.js`: dashboard login dan pengelolaan konten.
- `config.js`: Project URL dan Publishable Key Supabase.
- `schema.sql`: tabel, RLS, admin authorization, dan Storage bucket.
- `assets/adb-creative-team-logo.webp`: logo ADB Creative Team yang tampil di header, footer, dan dashboard admin.
- `assets/logo-sekolah.jpg`: arsip logo sekolah.

## Setup Supabase

1. Buka Supabase project `kgyhwhnpldlcdfhwzkto`.
2. Pastikan `config.js` berisi Project URL tanpa `/rest/v1/` dan Publishable Key. Jangan pernah menaruh Secret Key atau `service_role` di frontend.
3. Buka SQL Editor, jalankan seluruh `schema.sql` dari atas sampai bawah.
4. Buka Authentication → Users → Add User. Buat akun admin menggunakan email dan password yang dikelola pemilik website.
5. Salin UUID user tersebut.
6. Jalankan SQL berikut di SQL Editor dengan UUID akun admin yang sebenarnya:

```sql
insert into public.admins (user_id)
values ('UUID-AKUN-ADMIN')
on conflict (user_id) do nothing;
```

7. Deploy seluruh isi folder website, termasuk folder `assets` dan file `assets/adb-creative-team-logo.webp`, ke hosting static (GitHub Pages dapat digunakan).
8. Buka `admin.html`, login, lalu tambah foto, video, berita, pencapaian, agenda, atau pengumuman.

## Fitur CMS

- Foto dan video diunggah ke Supabase Storage bucket `media`.
- Berita, pencapaian, agenda, dan pengumuman disimpan di tabel `content_items`.
- Konten draft hanya dapat dilihat admin. Konten berstatus terbit dapat dibaca publik.
- Admin dapat menambah, mengedit, menerbitkan, menghapus konten, dan menghapus file media terkait.
- Feedback publik tetap memakai tabel `feedback` dari skema awal.

## Batas upload

Frontend membatasi file hingga 50 MB. Bucket membatasi tipe file ke JPEG, PNG, WebP, GIF, AVIF, MP4, WebM, dan QuickTime. Batas aktual layanan Supabase dapat bergantung pada paket dan pengaturan proyek. Untuk video besar, gunakan tautan YouTube dan simpan URL melalui pengembangan lanjutan.

## Keamanan

- Browser hanya memakai Publishable Key.
- RLS mengizinkan publik membaca konten yang sudah diterbitkan.
- Hanya UUID yang terdaftar di `public.admins` yang dapat mengelola konten dan file Storage.
- Jangan mengaktifkan pendaftaran admin publik.
- Aktifkan verifikasi email dan gunakan password admin yang kuat.

## Catatan hosting

GitHub Pages hanya menjalankan frontend statis. `app.py` adalah opsi Flask untuk hosting Python terpisah, bukan sesuatu yang berjalan di GitHub Pages. Website publik dan dashboard Supabase CMS tidak membutuhkan Flask.

## Instagram

https://www.instagram.com/adbcreative_team/

## Status

File sudah diperbarui dan pemeriksaan sintaks JavaScript lokal dilakukan. Koneksi langsung, login, upload, dan RLS tetap harus dites di project Supabase karena hasilnya bergantung pada konfigurasi project dan akun admin.
