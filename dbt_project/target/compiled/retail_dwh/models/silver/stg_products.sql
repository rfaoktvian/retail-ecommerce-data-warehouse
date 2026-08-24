-- Silver: products
-- Source: bronze.postgres_products
-- Cleaning:
--   1. Standardisasi nama kategori (lowercase, trim)
--   2. [DQ NOTE] 610 baris null product_category_name (1.85%) — dibiarkan null.
--      Tidak bisa di-impute secara akurat tanpa data tambahan.
--      Akan di-handle di gold layer dengan COALESCE ke 'uncategorized' jika diperlukan.
--   3. [DQ NOTE] 610 baris null product_name_length, product_description_length, product_photos_qty
--      — berkorelasi dengan baris yang sama (produk tanpa metadata teks), dibiarkan null.
--   4. [DQ FIX] 4 baris weight_g = 0 → di-nullify karena barang fisik tidak mungkin
--      beratnya nol (kemungkinan error input di source).
--   5. [DQ NOTE] 2 baris null weight_g, length_cm, height_cm, width_cm — dibiarkan null
--      (tidak cukup info untuk di-impute dengan aman).

select
    product_id,
    -- DQ Note: 610 null (1.85%), dibiarkan null
    lower(trim(product_category_name)) as product_category_name,
    -- DQ Note: 610 null, berkorelasi dengan produk tanpa metadata teks
    product_name_length,
    product_description_length,
    product_photos_qty,
    -- DQ Fix: 4 baris weight_g = 0 → null (barang fisik tidak mungkin beratnya nol)
    case
        when product_weight_g = 0 then null
        else product_weight_g
    end as weight_g,
    -- DQ Note: 2 null, dibiarkan null
    product_length_cm as length_cm,
    product_height_cm as height_cm,
    product_width_cm  as width_cm,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-03-018d48a9d681`.`bronze`.`postgres_products`
where product_id is not null