"""
migrate_to_postgres.py
Fase A — one-time seeding: migrasi 5 file CSV Olist ke PostgreSQL
menggunakan COPY (bulk load native PostgreSQL, bukan row-by-row insert).

Urutan load WAJIB mengikuti dependency FK:
customers -> products -> orders -> order_items -> order_payments

Cara pakai:
    python migrate_to_postgres.py

Prasyarat:
    - 9 file mentah Olist sudah ditaruh di datasets/raw/olist_kaggle/
    - Container PostgreSQL sudah jalan (docker compose up -d)
    - schema.sql sudah diterapkan (otomatis via Docker, atau manual via setup_postgres.py)
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

RAW_DIR = Path(__file__).resolve().parent.parent / "datasets" / "raw"

# Urutan WAJIB sesuai dependency FK: customers -> products -> orders -> order_items -> order_payments
# Setiap entry: (nama tabel tujuan, nama file CSV, list kolom SESUAI URUTAN kolom di file CSV)
LOAD_PLAN = [
    (
        "customers",
        "customers.csv",
        ["customer_id", "customer_unique_id", "customer_zip_code_prefix", "customer_city", "customer_state"],
    ),
    (
        "products",
        "products.csv",
        # Catatan: file asli Olist punya typo "product_name_lenght" / "product_description_lenght"
        # (kurang huruf "g"). Tidak masalah — COPY cocokkan berdasarkan POSISI, bukan nama header,
        # jadi kita tetap pakai nama kolom yang benar di sisi PostgreSQL.
        [
            "product_id",
            "product_category_name",
            "product_name_length",
            "product_description_length",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm",
        ],
    ),
    (
        "orders",
        "orders.csv",
        [
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    ),
    (
        "order_items",
        "order_items.csv",
        ["order_id", "order_item_id", "product_id", "seller_id", "shipping_limit_date", "price", "freight_value"],
    ),
    (
        "order_payments",
        "order_payments.csv",
        ["order_id", "payment_sequential", "payment_type", "payment_installments", "payment_value"],
    ),
]


def truncate_all(conn):
    """Kosongkan semua tabel dulu (urutan dibalik dari load, karena FK) supaya script aman dijalankan berkali-kali."""
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE order_payments, order_items, orders, products, customers RESTART IDENTITY CASCADE;")
    conn.commit()
    print("[OK] Semua tabel dikosongkan (TRUNCATE), siap di-load ulang.\n")


def copy_csv_to_table(conn, table_name: str, file_name: str, columns: list[str]):
    file_path = RAW_DIR / file_name
    if not file_path.exists():
        print(f"[ERROR] File tidak ditemukan: {file_path}")
        print(f"        Pastikan 9 file Olist sudah ditaruh di: {RAW_DIR}")
        sys.exit(1)

    column_list = ", ".join(columns)
    copy_sql = f"COPY {table_name} ({column_list}) FROM STDIN WITH (FORMAT csv, HEADER true)"

    with conn.cursor() as cur, open(file_path, "r", encoding="utf-8") as f:
        cur.copy_expert(copy_sql, f)

    with conn.cursor() as cur:
        cur.execute(f"SELECT COUNT(*) FROM {table_name};")
        count = cur.fetchone()[0]

    print(f"[OK] {table_name:<16} <- {file_name:<40} ({count:,} baris)")


def main():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
    except psycopg2.OperationalError as e:
        print(f"[ERROR] Gagal connect ke PostgreSQL: {e}")
        print("Pastikan container Postgres sudah jalan: docker compose up -d")
        sys.exit(1)

    conn.autocommit = False
    try:
        truncate_all(conn)
        for table_name, file_name, columns in LOAD_PLAN:
            copy_csv_to_table(conn, table_name, file_name, columns)
        conn.commit()
        print("\n[OK] Migrasi selesai, semua data ter-commit.")
    except Exception as e:
        conn.rollback()
        print(f"\n[ERROR] Migrasi gagal, rollback dilakukan: {e}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()