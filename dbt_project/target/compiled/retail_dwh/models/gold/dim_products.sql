-- Gold: dim_products
-- Grain: 1 baris = 1 product_id
-- DQ Decision: product_category_name null (610 produk, 1.85%) → di-coalesce ke 'uncategorized'
--   agar tidak muncul "(blank)" di chart dashboard. Nilai null asli tersimpan di silver.

select
    to_hex(md5(cast(coalesce(cast(product_id as string), '_dbt_utils_surrogate_key_null_') as string))) as product_key,

    product_id,
    coalesce(product_category_name, 'uncategorized') as product_category_name,

    -- Metadata teks produk (nullable — 610 produk tanpa metadata teks)
    product_name_length,
    product_description_length,
    product_photos_qty,

    -- Dimensi fisik (nullable — 2 produk tanpa data dimensi)
    weight_g,
    length_cm,
    height_cm,
    width_cm

from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_products`