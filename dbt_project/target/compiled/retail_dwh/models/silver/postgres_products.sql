-- Silver: products
-- Cleaning: standardisasi nama kategori (lowercase, trim), rename kolom weight/dimensi

select
    product_id,
    lower(trim(product_category_name)) as product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    -- Data quality fix: 4 produk punya weight_g = 0, tidak masuk akal untuk barang fisik.
    -- Di-treat sebagai missing (NULL), bukan literal nol.
    case when product_weight_g = 0 then null else product_weight_g end as weight_g,
    product_length_cm as length_cm,
    product_height_cm as height_cm,
    product_width_cm as width_cm,
    dwh_extracted_at,
    dwh_source_system

from `qwiklabs-gcp-04-05c5517686d1`.`bronze`.`postgres_products`
where product_id is not null