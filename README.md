# LIFE+ V1

Aplikasi produktivitas harian Android berbasis Flutter.

## Fitur V1
- Beranda/dashboard
- Tambah tugas
- Tanggal, jam, prioritas, catatan
- Checklist tugas selesai
- Filter semua/belum selesai/selesai
- Pengingat tersimpan lokal
- Statistik tugas
- Pengaturan nama pengguna
- Data tersimpan di HP menggunakan SharedPreferences

## Build
1. Install Flutter.
2. Jalankan:
   flutter pub get
   flutter run

Untuk APK:
   flutter build apk --release

Untuk AAB:
   flutter build appbundle --release

Hasil biasanya:
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab

## Catatan
Notifikasi sistem Android belum diaktifkan pada V1 pertama. Halaman Pengingat dan penyimpanan pengingat sudah disiapkan sehingga tahap berikutnya bisa menambahkan notifikasi terjadwal.
