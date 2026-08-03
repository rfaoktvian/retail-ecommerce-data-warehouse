"""
extract_postgres.py
Menarik 5 tabel dari PostgreSQL, menyimpan sebagai Parquet ke staging lokal
dengan penamaan sesuai naming_conventions.md: postgres_<entity>.parquet

Cara pakai (manual/testing di luar Airflow):
    python extract/extract_postgres.py
"""

import os
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

DB_URI = (
    f"postgresql+psycopg2://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}"
    f"@{os.getenv('POSTGRES_HOST', 'localhost')}:{os.getenv('POSTGRES_PORT', '5432')}"
    f"/{os.getenv('POSTGRES_DB')}"
)

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "extracted"

TABLES = ["customers", "products", "orders", "order_items", "order_payments"]


def extract_table(engine, table_name: str) -> Path:
    df = pd.read_sql(f"SELECT * FROM {table_name}", engine)

    # Technical column sesuai naming_conventions.md (prefix dwh_)
    df["dwh_extracted_at"] = datetime.now(timezone.utc)
    df["dwh_source_system"] = "postgres"

    output_path = OUTPUT_DIR / f"postgres_{table_name}.parquet"
    df.to_parquet(output_path, index=False)

    print(f"[OK] postgres.{table_name:<16} -> {output_path.name:<32} ({len(df):,} baris)")
    return output_path


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    engine = create_engine(DB_URI)

    extracted_files = []
    for table_name in TABLES:
        extracted_files.append(extract_table(engine, table_name))

    engine.dispose()
    print(f"\n[OK] {len(extracted_files)} file berhasil di-extract ke {OUTPUT_DIR}")
    return extracted_files


if __name__ == "__main__":
    main()