"""
copy_flat_sources.py
Fase A — menyiapkan sellers.csv & geolocation.csv apa adanya (tanpa transformasi),
karena keduanya memang tetap jadi CSV di arsitektur multi-source project ini
(bukan masuk PostgreSQL, bukan JSON).

Cara pakai:
    python copy_flat_sources.py
"""

import shutil
from pathlib import Path

RAW_DIR = Path(__file__).resolve().parent.parent / "datasets" / "raw"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "datasets" / "raw" / "file_sources"

FILES_TO_COPY = {
    "sellers.csv": "sellers.csv",
    "geolocation.csv": "geolocation.csv",
}


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for source_name, target_name in FILES_TO_COPY.items():
        source_path = RAW_DIR / source_name
        target_path = OUTPUT_DIR / target_name

        if not source_path.exists():
            print(f"[ERROR] File tidak ditemukan: {source_path}")
            continue

        shutil.copy2(source_path, target_path)
        print(f"[OK] {source_name} -> {target_path}")


if __name__ == "__main__":
    main()