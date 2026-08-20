select
    to_hex(md5(cast(coalesce(cast(product_id as string), '_dbt_utils_surrogate_key_null_') as string))) as product_key,
    product_id,
    -- 610 produk tanpa kategori (data quality issue asli dari source) —
    -- di silver tetap NULL (truthful), di sini baru di-coalesce supaya
    -- enak ditampilkan di dashboard (tidak ada "(blank)" di chart)
    coalesce(product_category_name, 'uncategorized') as product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    weight_g,
    length_cm,
    height_cm,
    width_cm

from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_products`