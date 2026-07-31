"""
setup_postgres.py
Utility untuk menjalankan (atau re-run) schema.sql ke database PostgreSQL.

Kegunaan:
- Docker sudah otomatis jalankan schema.sql saat container PERTAMA KALI dibuat
  (lewat docker-entrypoint-initdb.d).
- Script ini untuk kasus lain: kamu edit schema.sql di tengah development dan
  mau re-apply TANPA reset volume Docker (yang akan menghapus data migrasi).
- schema.sql sudah pakai `DROP TABLE IF EXISTS`, jadi aman dijalankan berkali-kali.

Cara pakai:
    python setup_postgres.py
"""

import os
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "localhost"),
    "port": os.getenv("POSTGRES_PORT", "5432"),
    "dbname": os.getenv("POSTGRES_DB"),
    "user": os.getenv("POSTGRES_USER"),
    "password": os.getenv("POSTGRES_PASSWORD"),
}

SCHEMA_PATH = Path(__file__).resolve().parent / "schema.sql"


def run_schema():
    if not SCHEMA_PATH.exists():
        print(f"[ERROR] schema.sql tidak ditemukan di: {SCHEMA_PATH}")
        sys.exit(1)

    schema_sql = SCHEMA_PATH.read_text(encoding="utf-8")

    print(f"Menghubungkan ke database '{DB_CONFIG['dbname']}' di {DB_CONFIG['host']}:{DB_CONFIG['port']}...")

    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.OperationalError as e:
        print(f"[ERROR] Gagal connect ke PostgreSQL: {e}")
        print("Pastikan container Postgres sudah jalan: docker compose up -d")
        sys.exit(1)

    conn.autocommit = False
    try:
        with conn.cursor() as cur:
            print("Menjalankan schema.sql (DROP + CREATE TABLE)...")
            cur.execute(schema_sql)
        conn.commit()
        print("[OK] Schema berhasil diterapkan.")
    except Exception as e:
        conn.rollback()
        print(f"[ERROR] Gagal menjalankan schema.sql, rollback dilakukan: {e}")
        sys.exit(1)
    finally:
        conn.close()

    verify_tables()


def verify_tables():
    """Cek ulang tabel apa saja yang berhasil dibuat, sebagai konfirmasi visual."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name;
                """
            )
            tables = [row[0] for row in cur.fetchall()]
        conn.close()

        expected = {"customers", "products", "orders", "order_items", "order_payments"}
        print("\nTabel yang terdeteksi di database:")
        for t in tables:
            print(f"  - {t}")

        missing = expected - set(tables)
        if missing:
            print(f"\n[WARNING] Tabel berikut belum terbentuk: {missing}")
        else:
            print("\n[OK] Semua 5 tabel yang diharapkan sudah ada.")

    except Exception as e:
        print(f"[WARNING] Tidak bisa verifikasi tabel: {e}")


if __name__ == "__main__":
    run_schema()