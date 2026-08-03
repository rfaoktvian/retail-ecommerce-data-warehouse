"""
extract_csv.py
Fase B — Extract (dipanggil oleh Airflow task `extract_csv`).

Membaca sellers.csv & geolocation.csv dari datasets/raw/file_sources/,
menyimpan sebagai Parquet ke staging lokal dengan penamaan sesuai
naming_conventions.md: csv_<entity>.parquet

Cara pakai (manual/testing di luar Airflow):
    python extract/extract_csv.py
"""

from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

SOURCE_DIR = Path(__file__).resolve().parent.parent / "datasets" / "raw" / "file_sources"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "extracted"

FILES = {
    "sellers.csv": "csv_sellers.parquet",
    "geolocation.csv": "csv_geolocation.parquet",
}


def extract_file(source_name: str, output_name: str) -> Path:
    source_path = SOURCE_DIR / source_name
    if not source_path.exists():
        raise FileNotFoundError(f"File tidak ditemukan: {source_path}")

    df = pd.read_csv(source_path)

    # Technical column sesuai naming_conventions.md (prefix dwh_)
    df["dwh_extracted_at"] = datetime.now(timezone.utc)
    df["dwh_source_system"] = "csv"

    output_path = OUTPUT_DIR / output_name
    df.to_parquet(output_path, index=False)

    print(f"[OK] {source_name:<20} -> {output_path.name:<28} ({len(df):,} baris)")
    return output_path


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    extracted_files = []
    for source_name, output_name in FILES.items():
        extracted_files.append(extract_file(source_name, output_name))

    print(f"\n[OK] {len(extracted_files)} file berhasil di-extract ke {OUTPUT_DIR}")
    return extracted_files


if __name__ == "__main__":
    main()