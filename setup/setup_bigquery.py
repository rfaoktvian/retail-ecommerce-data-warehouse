"""
setup_bigquery.py
Fase A (setup, one-time) — membuat dataset bronze/silver/gold di BigQuery.
Aman dijalankan berkali-kali (idempotent, pakai exists_ok=True).

Cara pakai:
    python setup/setup_bigquery.py
"""

import os

from google.cloud import bigquery
from dotenv import load_dotenv

load_dotenv()

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
LOCATION = os.getenv("GCP_LOCATION", "asia-southeast2")

DATASETS = {
    "bronze": "Raw data, apa adanya dari hasil extract (bronze layer)",
    "silver": "Data yang sudah dibersihkan & distandarisasi (silver layer)",
    "gold": "Data siap pakai untuk analisis & dashboard (gold layer, star schema)",
}


def main():
    client = bigquery.Client(project=PROJECT_ID)

    for dataset_id, description in DATASETS.items():
        full_dataset_id = f"{PROJECT_ID}.{dataset_id}"
        dataset = bigquery.Dataset(full_dataset_id)
        dataset.location = LOCATION
        dataset.description = description

        created_dataset = client.create_dataset(dataset, exists_ok=True)
        print(f"[OK] Dataset '{created_dataset.dataset_id}' siap di lokasi {created_dataset.location}")

    print(f"\n[OK] Semua dataset siap di project '{PROJECT_ID}'.")


if __name__ == "__main__":
    main()