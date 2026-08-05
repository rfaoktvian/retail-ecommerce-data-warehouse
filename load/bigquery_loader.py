"""
bigquery_loader.py
Fase B — Load (dipanggil oleh Airflow task `load_bronze`, setelah gcs_upload.py).

Load semua file Parquet dari GCS landing zone (partisi tanggal tertentu)
ke tabel bronze BigQuery. Nama tabel diturunkan otomatis dari nama file
(sudah sesuai naming_conventions.md: postgres_orders.parquet -> bronze.postgres_orders).

Cara pakai (manual/testing di luar Airflow):
    python load/bigquery_loader.py                # pakai tanggal hari ini
    python load/bigquery_loader.py --date 2026-08-03
"""

import argparse
import os
from datetime import datetime, timezone

from google.cloud import bigquery, storage
from dotenv import load_dotenv

load_dotenv()

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
DATASET_ID = "bronze"


def load_table_from_gcs(client: bigquery.Client, blob_name: str):
    # blob_name contoh: "landing/2026-08-03/postgres_orders.parquet"
    file_name = blob_name.split("/")[-1]
    table_name = file_name.replace(".parquet", "")  # -> "postgres_orders"

    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
    gcs_uri = f"gs://{BUCKET_NAME}/{blob_name}"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.PARQUET,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # bronze full-refresh tiap run
        autodetect=True,
    )

    load_job = client.load_table_from_uri(gcs_uri, table_ref, job_config=job_config)
    load_job.result()  # tunggu sampai job selesai

    table = client.get_table(table_ref)
    print(f"[OK] {gcs_uri} -> {table_ref} ({table.num_rows:,} baris)")


def main(run_date: str):
    bq_client = bigquery.Client(project=PROJECT_ID)
    storage_client = storage.Client(project=PROJECT_ID)

    prefix = f"landing/{run_date}/"
    blobs = list(storage_client.list_blobs(BUCKET_NAME, prefix=prefix))
    parquet_blobs = [b for b in blobs if b.name.endswith(".parquet")]

    if not parquet_blobs:
        print(f"[WARNING] Tidak ada file .parquet ditemukan di gs://{BUCKET_NAME}/{prefix}")
        return

    for blob in parquet_blobs:
        load_table_from_gcs(bq_client, blob.name)

    print(f"\n[OK] {len(parquet_blobs)} tabel berhasil di-load ke dataset '{DATASET_ID}'.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--date",
        default=datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        help="Tanggal partisi landing zone, format YYYY-MM-DD (default: hari ini)",
    )
    args = parser.parse_args()
    main(args.date)