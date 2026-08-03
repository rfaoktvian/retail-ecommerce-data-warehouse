"""
extract_json.py
Fase B — Extract (dipanggil oleh Airflow task `extract_json`).

Membaca reviews.json dari datasets/raw/file_sources/, menyimpan sebagai
Parquet ke staging lokal dengan penamaan sesuai naming_conventions.md:
json_<entity>.parquet

Cara pakai (manual/testing di luar Airflow):
    python extract/extract_json.py
"""

import json
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

SOURCE_FILE = Path(__file__).resolve().parent.parent / "datasets" / "raw" / "file_sources" / "reviews.json"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "extracted"
OUTPUT_FILE = OUTPUT_DIR / "json_reviews.parquet"


def main():
    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f"File tidak ditemukan: {SOURCE_FILE}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with open(SOURCE_FILE, "r", encoding="utf-8") as f:
        records = json.load(f)

    df = pd.json_normalize(records)

    # Technical column sesuai naming_conventions.md (prefix dwh_)
    df["dwh_extracted_at"] = datetime.now(timezone.utc)
    df["dwh_source_system"] = "json"

    df.to_parquet(OUTPUT_FILE, index=False)

    print(f"[OK] reviews.json -> {OUTPUT_FILE.name} ({len(df):,} baris)")
    return OUTPUT_FILE


if __name__ == "__main__":
    main()