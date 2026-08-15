"""
data_quality_check.py
Comprehensive data quality profiling untuk seluruh dataset Olist,
sebelum menulis logic cleaning di dbt silver.

Cara pakai: copy fungsi-fungsi ini + bagian "RUN ALL CHECKS" ke notebook
(01_data_understanding.ipynb), atau jalankan langsung:
    python data_quality_check.py
"""

import pandas as pd

RAW_DIR = "../../datasets/raw/"  # sesuaikan kalau lokasi file beda
RAW1_DIR = "../../datasets/raw/file_sources/"

def load(filename):
    return pd.read_csv(f"{RAW_DIR}{filename}")

def load1(filename):
    return pd.read_csv(f"{RAW1_DIR}{filename}")


# ============================================================
# HELPER FUNCTIONS — satu fungsi per dimensi data quality
# ============================================================

def check_completeness(df, name):
    """Dimensi: Completeness — kolom mana yang banyak kosong?"""
    print(f"\n[{name}] Completeness")
    null_count = df.isnull().sum()
    null_pct = (df.isnull().mean() * 100).round(2)
    result = pd.DataFrame({"null_count": null_count, "null_pct(%)": null_pct})
    result = result[result["null_count"] > 0]
    if result.empty:
        print("  Tidak ada missing value.")
    else:
        print(result)


def check_duplicates(df, name, subset=None):
    """Dimensi: Uniqueness — ada baris/key yang duplikat?"""
    dup_count = df.duplicated(subset=subset).sum()
    key_desc = subset if subset else "seluruh kolom (full row)"
    print(f"\n[{name}] Duplicate check (berdasarkan {key_desc}): {dup_count} baris duplikat")


def check_numeric_outliers(df, name, cols):
    """Dimensi: Validity — apakah ada nilai numerik yang tidak masuk akal (negatif/nol)?"""
    print(f"\n[{name}] Numeric range check")
    print(df[cols].describe().round(2))
    for col in cols:
        negative = (df[col] < 0).sum()
        zero = (df[col] == 0).sum()
        print(f"  {col}: negatif={negative}, bernilai nol={zero}")


def check_category_consistency(df, name, col, top_n=15):
    """Dimensi: Consistency — apakah penulisan kategori konsisten (tidak typo/beda casing)?"""
    print(f"\n[{name}] Value counts kolom '{col}' (top {top_n} dari {df[col].nunique()} kategori unik)")
    print(df[col].value_counts(dropna=False).head(top_n))


def check_valid_range(df, name, col, valid_values):
    """Dimensi: Validity — apakah nilai kolom sesuai domain yang diperbolehkan?"""
    invalid = df[~df[col].isin(valid_values)]
    print(f"\n[{name}] '{col}' di luar nilai valid {valid_values}: {len(invalid)} baris")


def check_referential_integrity(df_child, df_parent, child_col, parent_col, name):
    """Dimensi: Referential Integrity — apakah semua FK di child ada di parent?"""
    mask = df_child[child_col].notna() & ~df_child[child_col].isin(df_parent[parent_col])
    orphan = df_child[mask]
    print(f"\n[{name}] Orphan check: '{child_col}' tidak ditemukan di parent "
          f"-> {orphan[child_col].nunique()} nilai unik ({len(orphan)} baris terdampak)")


def check_date_logic(df, name, earlier_col, later_col):
    """Dimensi: Accuracy/Logic — apakah urutan tanggal logis (later >= earlier)?"""
    d = df[[earlier_col, later_col]].copy()
    d[earlier_col] = pd.to_datetime(d[earlier_col], errors="coerce")
    d[later_col] = pd.to_datetime(d[later_col], errors="coerce")
    invalid = d[d[later_col] < d[earlier_col]]
    print(f"\n[{name}] Date logic: '{later_col}' < '{earlier_col}' -> {len(invalid)} baris invalid")


# ============================================================
# LOAD SEMUA DATASET
# ============================================================

customers = load("customers.csv")
orders = load("orders.csv")
products = load("products.csv")
order_items = load("order_items.csv")
order_payments = load("order_payments.csv")
order_reviews = load("order_reviews.csv")
sellers = load1("sellers.csv")
geolocation = load1("geolocation.csv")


# ============================================================
# RUN ALL CHECKS
# ============================================================

print("=" * 70)
print("1. CUSTOMERS")
print("=" * 70)
check_completeness(customers, "customers")
check_duplicates(customers, "customers", subset=["customer_id"])
check_category_consistency(customers, "customers", "customer_city")
check_category_consistency(customers, "customers", "customer_state")

print("\n" + "=" * 70)
print("2. ORDERS")
print("=" * 70)
check_completeness(orders, "orders")
check_duplicates(orders, "orders", subset=["order_id"])
check_category_consistency(orders, "orders", "order_status")
check_date_logic(orders, "orders", "order_purchase_timestamp", "order_approved_at")
check_date_logic(orders, "orders", "order_purchase_timestamp", "order_delivered_carrier_date")
check_date_logic(orders, "orders", "order_purchase_timestamp", "order_delivered_customer_date")
check_referential_integrity(orders, customers, "customer_id", "customer_id", "orders -> customers")

print("\n" + "=" * 70)
print("3. PRODUCTS")
print("=" * 70)
check_completeness(products, "products")
check_duplicates(products, "products", subset=["product_id"])
check_numeric_outliers(
    products, "products",
    ["product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"]
)

print("\n" + "=" * 70)
print("4. ORDER_ITEMS")
print("=" * 70)
check_completeness(order_items, "order_items")
check_duplicates(order_items, "order_items", subset=["order_id", "order_item_id"])
check_numeric_outliers(order_items, "order_items", ["price", "freight_value"])
check_referential_integrity(order_items, orders, "order_id", "order_id", "order_items -> orders")
check_referential_integrity(order_items, products, "product_id", "product_id", "order_items -> products")
check_referential_integrity(order_items, sellers, "seller_id", "seller_id", "order_items -> sellers")

print("\n" + "=" * 70)
print("5. ORDER_PAYMENTS")
print("=" * 70)
check_completeness(order_payments, "order_payments")
check_numeric_outliers(order_payments, "order_payments", ["payment_value", "payment_installments"])
check_category_consistency(order_payments, "order_payments", "payment_type")
check_referential_integrity(order_payments, orders, "order_id", "order_id", "order_payments -> orders")

print("\n" + "=" * 70)
print("6. ORDER_REVIEWS")
print("=" * 70)
check_completeness(order_reviews, "order_reviews")
check_duplicates(order_reviews, "order_reviews", subset=["review_id"])
check_valid_range(order_reviews, "order_reviews", "review_score", [1, 2, 3, 4, 5])
check_date_logic(order_reviews, "order_reviews", "review_creation_date", "review_answer_timestamp")
check_referential_integrity(order_reviews, orders, "order_id", "order_id", "order_reviews -> orders")

print("\n" + "=" * 70)
print("7. SELLERS")
print("=" * 70)
check_completeness(sellers, "sellers")
check_duplicates(sellers, "sellers", subset=["seller_id"])
check_category_consistency(sellers, "sellers", "seller_city")
check_category_consistency(sellers, "sellers", "seller_state")

print("\n" + "=" * 70)
print("8. GEOLOCATION")
print("=" * 70)
check_completeness(geolocation, "geolocation")
check_duplicates(geolocation, "geolocation")  
unique_zip = geolocation["geolocation_zip_code_prefix"].nunique()
print(f"\n[geolocation] Unique zip_code_prefix: {unique_zip:,} dari {len(geolocation):,} baris total "
      f"(rasio duplikat per zip tinggi = wajar, akan di-agregasi di silver)")

check_duplicates(order_payments, "order_payments")

check_category_consistency(products, "products", "product_category_name")

check_referential_integrity(orders, order_items, "order_id", "order_id", "orders -> order_items (reverse)")
check_referential_integrity(orders, order_payments, "order_id", "order_id", "orders -> order_payments (reverse)")

print("\n" + "=" * 70)
print("SELESAI")
print("=" * 70)