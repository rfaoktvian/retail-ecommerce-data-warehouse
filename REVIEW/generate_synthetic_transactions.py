"""
Generate data sintetis untuk tabel `order_items` dan `payments`,
lalu insert ke PostgreSQL (simulasi sistem OLTP retail).

PENTING: order_id, product_id, dan seller_id yang dipakai di sini
diambil langsung dari dataset Olist (orders.csv, products.csv,
sellers.csv) supaya relasinya konsisten dan bisa di-join dengan
sumber CRM & Product saat proses transform (silver layer).

Cara pakai:
    1. Pastikan file Olist berikut ada di RAW_DATA_DIR:
       orders.csv, order_items.csv (opsional, hanya untuk referensi jumlah item),
       products.csv, sellers.csv
    2. docker compose -f docker/docker-compose.yml up -d
    3. pip install -r requirements.txt
    4. python scripts/generate_synthetic_transactions.py
"""

import os
import random

import pandas as pd
from dotenv import load_dotenv
from faker import Faker
from sqlalchemy import create_engine

load_dotenv()
fake = Faker()
random.seed(42)
Faker.seed(42)

RAW_DATA_DIR = os.getenv("RAW_DATA_DIR", "datasets/raw")

PAYMENT_TYPES = (
    ["credit_card"] * 60 + ["boleto"] * 20 + ["voucher"] * 10 + ["debit_card"] * 10
)


def get_engine():
    """Buat koneksi SQLAlchemy ke PostgreSQL berdasarkan .env"""
    user = os.getenv("DB_USER", "retail_admin")
    password = os.getenv("DB_PASSWORD", "retail_pass")
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    db = os.getenv("DB_NAME", "retail_oltp")
    url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}"
    return create_engine(url)


def load_reference_ids(raw_dir: str):
    """Ambil order_id, product_id, seller_id dari dataset Olist (CRM & Product source)"""
    orders = pd.read_csv(os.path.join(raw_dir, "orders.csv"), usecols=["order_id"])
    products = pd.read_csv(os.path.join(raw_dir, "products.csv"), usecols=["product_id"])
    sellers = pd.read_csv(os.path.join(raw_dir, "sellers.csv"), usecols=["seller_id"])
    return orders["order_id"].tolist(), products["product_id"].tolist(), sellers["seller_id"].tolist()


def generate_order_items(order_ids, product_ids, seller_ids) -> pd.DataFrame:
    """Setiap order punya 1-3 item, product_id & seller_id diambil dari data referensi asli"""
    rows = []
    for order_id in order_ids:
        n_items = random.choices([1, 2, 3], weights=[70, 20, 10])[0]
        for _ in range(n_items):
            rows.append(
                {
                    "order_id": order_id,
                    "product_id": random.choice(product_ids),
                    "seller_id": random.choice(seller_ids),
                    "quantity": random.choices([1, 2, 3], weights=[85, 10, 5])[0],
                    "price": round(random.uniform(15, 500), 2),
                    "freight_value": round(random.uniform(5, 45), 2),
                }
            )
    return pd.DataFrame(rows)


def generate_payments(order_items_df: pd.DataFrame) -> pd.DataFrame:
    """Hitung total per order lalu buat 1-2 baris payment yang jumlahnya konsisten dengan total tsb"""
    order_totals = (
        order_items_df.assign(line_total=lambda d: d["price"] * d["quantity"] + d["freight_value"])
        .groupby("order_id")["line_total"]
        .sum()
        .reset_index()
    )

    rows = []
    for _, row in order_totals.iterrows():
        order_id, total = row["order_id"], round(row["line_total"], 2)
        split_payment = random.random() < 0.1  # 10% order dibayar 2 metode (mis. voucher + kartu)

        if split_payment:
            voucher_amount = round(total * random.uniform(0.1, 0.3), 2)
            remainder = round(total - voucher_amount, 2)
            rows.append(_payment_row(order_id, 1, "voucher", 1, voucher_amount))
            rows.append(_payment_row(order_id, 2, "credit_card", _installments(), remainder))
        else:
            payment_type = random.choice(PAYMENT_TYPES)
            installments = _installments() if payment_type == "credit_card" else 1
            rows.append(_payment_row(order_id, 1, payment_type, installments, total))

    return pd.DataFrame(rows)


def _installments() -> int:
    return random.choices(list(range(1, 13)), weights=[30, 20, 15, 10, 8, 5, 3, 3, 2, 2, 1, 1])[0]


def _payment_row(order_id, seq, ptype, installments, value):
    return {
        "order_id": order_id,
        "payment_sequential": seq,
        "payment_type": ptype,
        "payment_installments": installments,
        "payment_value": value,
    }


def main():
    print("Membaca reference ID dari dataset Olist...")
    order_ids, product_ids, seller_ids = load_reference_ids(RAW_DATA_DIR)
    print(f"  orders: {len(order_ids)} | products: {len(product_ids)} | sellers: {len(seller_ids)}")

    print("Generating order_items...")
    order_items_df = generate_order_items(order_ids, product_ids, seller_ids)
    print(f"  {len(order_items_df)} baris order_items dibuat")

    print("Generating payments...")
    payments_df = generate_payments(order_items_df)
    print(f"  {len(payments_df)} baris payments dibuat")

    print("Menulis ke PostgreSQL...")
    engine = get_engine()
    order_items_df.to_sql("order_items", engine, if_exists="append", index=False, chunksize=5000)
    payments_df.to_sql("payments", engine, if_exists="append", index=False, chunksize=5000)

    print("Selesai. Data sintetis sudah tersimpan di PostgreSQL (order_items & payments).")


if __name__ == "__main__":
    main()
