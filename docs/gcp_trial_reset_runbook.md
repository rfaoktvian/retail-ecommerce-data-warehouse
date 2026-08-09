# **GCP Trial Session Reset — Runbook**

Dokumen ini khusus untuk kondisi sementara: akun GCP yang dipakai adalah **trial dari event Google Arcade**, yang otomatis reset setiap ± 2 jam (project, service account, bucket ikut terhapus). Checklist ini supaya proses "mulai ulang" tidak perlu menebak-nebak lagi.

> **Catatan jangka panjang**: kalau memungkinkan, disarankan pindah ke akun GCP pribadi (free tier permanen, tidak reset) begitu kendala pendaftarannya selesai — trial 2 jam ini cukup menghambat untuk development yang butuh iterasi berkali-kali.

---

## Yang TIDAK perlu diulang saat trial reset

Supaya jelas dulu — bagian ini **aman, tidak terpengaruh** reset GCP:

- ✅ Database **PostgreSQL** (jalan di Docker lokal, tidak ada hubungannya dengan GCP)
- ✅ Data hasil Fase A (`datasets/raw/file_sources/`, isi PostgreSQL)
- ✅ File hasil extract di `data/extracted/*.parquet` (selama belum dihapus manual)
- ✅ Semua kode: `extract/*.py`, `dbt_project/models/*.sql`, `schema.sql`, dst — tidak ada yang perlu diedit isinya
- ✅ `naming_conventions.md`, struktur folder, `docker-compose.yml`

Yang reset **hanya sisi GCP**: project, bucket, service account, dataset BigQuery.

---

## Checklist — dilakukan SETIAP kali mulai sesi trial baru

### 1. Buat GCP project baru
- Catat **Project ID** baru (beda dari sebelumnya, GCP generate otomatis/manual)

### 2. Buat GCS bucket baru
- Masuk **Cloud Storage → Create bucket**
- Nama harus unik global — kalau nama lama (`retail-dwh-landing-rafa`) sudah tidak dipakai project lama (biasanya tersedia lagi setelah project dihapus, tapi tidak selalu instan), coba pakai nama yang sama. Kalau gagal, tambah suffix, misal `retail-dwh-landing-rafa-v2`
- Location: **`asia-southeast2`** (Jakarta) — tetap sama seperti sebelumnya

### 3. Buat service account baru
- **IAM & Admin → Service Accounts → Create Service Account**
- Nama: `retail-dwh-pipeline` (boleh sama)
- Roles yang perlu ditambahkan lagi:
  - `Storage Object Admin`
  - `BigQuery Data Editor`
  - `BigQuery Job User`

### 4. Download JSON key baru
- Tab **Keys → Add Key → Create new key → JSON**
- **Timpa** file lama di `secrets/gcp-service-account.json` dengan yang baru (nama file boleh sama persis, supaya `.env` tidak perlu diubah path-nya)

### 5. Update `.env`
Ubah 2 baris ini (isi sesuai project/bucket baru):
```dotenv
GCP_PROJECT_ID=<project-id-baru>
GCS_BUCKET_NAME=<nama-bucket-baru>
```
(`GOOGLE_APPLICATION_CREDENTIALS=secrets/gcp-service-account.json` tidak perlu diubah kalau nama file key tetap sama)

### 6. Load ulang environment variable untuk sesi terminal (khusus dbt)
dbt **tidak otomatis baca file `.env`** seperti script Python (`load_dotenv()`). Jalankan ini di PowerShell setiap buka terminal baru sebelum pakai dbt:
```powershell
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}
```
(atau pakai `load_env.ps1` yang sudah disiapkan — lihat bagian bawah)

### 7. Re-run setup dataset BigQuery (project baru = dataset belum ada)
```bash
python setup/setup_bigquery.py
```

### 8. Re-run upload ke GCS (bucket baru = kosong)
```bash
python staging/gcs_upload.py
```
> Kalau folder `data/extracted/` sudah kosong/lama, jalankan dulu ulang `extract/extract_postgres.py`, `extract_csv.py`, `extract_json.py`

### 9. Re-run load ke BigQuery bronze
```bash
python load/bigquery_loader.py
```

### 10. Re-run dbt (silver lalu gold)
```bash
cd dbt_project
dbt run --select silver
dbt test --select silver
dbt run --select gold
dbt test --select gold
```

### 11. (Kalau sudah connect Looker Studio) update data source
- Buka dashboard di Looker Studio → **Resource → Manage added data sources** → edit koneksi → ganti ke project/dataset BigQuery yang baru

---

## Ringkasan cepat (cheat sheet)

| # | Aksi | Wajib diulang tiap reset? |
|---|---|---|
| 1 | Buat GCP project baru | ✅ |
| 2 | Buat GCS bucket baru | ✅ |
| 3 | Buat service account + roles | ✅ |
| 4 | Download & timpa JSON key | ✅ |
| 5 | Update `GCP_PROJECT_ID`, `GCS_BUCKET_NAME` di `.env` | ✅ |
| 6 | Load env var ke sesi terminal (`load_env.ps1`) | ✅ (tiap buka terminal baru) |
| 7 | `python setup/setup_bigquery.py` | ✅ |
| 8 | `python staging/gcs_upload.py` | ✅ |
| 9 | `python load/bigquery_loader.py` | ✅ |
| 10 | `dbt run` + `dbt test` (silver & gold) | ✅ |
| 11 | Update koneksi Looker Studio | Hanya kalau sudah setup dashboard |
| — | PostgreSQL, Fase A, kode project | ❌ tidak perlu diulang |