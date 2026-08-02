"""
convert_reviews_to_json.py
Fase A — konversi olist_order_reviews_dataset.csv menjadi reviews.json.

Tujuan: mensimulasikan data ini seolah datang dari API review pihak ketiga
(format JSON, key camelCase), sesuai skenario arsitektur multi-source project ini.

Cara pakai:
    python convert_reviews_to_json.py
"""

import json
from pathlib import Path

import pandas as pd

RAW_DIR = Path(__file__).resolve().parent.parent / "datasets" / "raw"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "datasets" / "raw" / "file_sources"

SOURCE_FILE = RAW_DIR / "order_reviews.csv"
OUTPUT_FILE = OUTPUT_DIR / "reviews.json"

# Mapping kolom asli (snake_case) -> camelCase, supaya terasa seperti response API sungguhan
COLUMN_MAPPING = {
    "review_id": "reviewId",
    "order_id": "orderId",
    "review_score": "reviewScore",
    "review_comment_title": "commentTitle",
    "review_comment_message": "commentMessage",
    "review_creation_date": "createdAt",
    "review_answer_timestamp": "answeredAt",
}


def main():
    if not SOURCE_FILE.exists():
        print(f"[ERROR] File tidak ditemukan: {SOURCE_FILE}")
        return

    df = pd.read_csv(SOURCE_FILE)
    df = df.rename(columns=COLUMN_MAPPING)
    df = df[list(COLUMN_MAPPING.values())]

    # Ganti NaN -> None supaya jadi `null` yang valid di JSON (bukan string "NaN")
    df = df.where(pd.notnull(df), None)

    records = df.to_dict(orient="records")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(records, f, indent=2, ensure_ascii=False)

    print(f"[OK] {len(records):,} review berhasil dikonversi -> {OUTPUT_FILE}")


if __name__ == "__main__":
    main()