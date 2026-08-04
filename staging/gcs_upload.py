"""
gcs_upload.py
Fase B — Staging (dipanggil oleh Airflow task setelah extract, sebelum load ke BigQuery).

Upload semua file Parquet hasil extract (data/extracted/) ke GCS landing zone,
dipartisi per tanggal supaya history tiap run pipeline tetap tersimpan.

Cara pakai (manual/testing di luar Airflow):
    python staging/gcs_upload.py
"""

import os
from datetime import datetime, timezone
from pathlib import Path

from google.cloud import storage
from dotenv import load_dotenv

load_dotenv()

BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
PROJECT_ID = os.getenv("GCP_PROJECT_ID")

LOCAL_DIR = Path(__file__).resolve().parent.parent / "data" / "extracted"

# Landing zone dipartisi per tanggal run, contoh:
# gs://<bucket>/landing/2026-08-03/postgres_orders.parquet
RUN_DATE = datetime.now(timezone.utc).strftime("%Y-%m-%d")
GCS_PREFIX = f"landing/{RUN_DATE}"


def upload_file(client: storage.Client, local_path: Path) -> str:
    bucket = client.bucket(BUCKET_NAME)
    blob_name = f"{GCS_PREFIX}/{local_path.name}"
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(str(local_path))

    gcs_uri = f"gs://{BUCKET_NAME}/{blob_name}"
    print(f"[OK] {local_path.name:<32} -> {gcs_uri}")
    return gcs_uri


def main():
    if not LOCAL_DIR.exists():
        raise FileNotFoundError(f"Folder tidak ditemukan: {LOCAL_DIR}. Jalankan extract/*.py dulu.")

    parquet_files = sorted(LOCAL_DIR.glob("*.parquet"))
    if not parquet_files:
        print(f"[WARNING] Tidak ada file .parquet di {LOCAL_DIR}. Jalankan extract/*.py dulu.")
        return []

    client = storage.Client(project=PROJECT_ID)

    uploaded_uris = []
    for file_path in parquet_files:
        uploaded_uris.append(upload_file(client, file_path))

    print(f"\n[OK] {len(uploaded_uris)} file berhasil di-upload ke gs://{BUCKET_NAME}/{GCS_PREFIX}/")
    return uploaded_uris


if __name__ == "__main__":
    main()