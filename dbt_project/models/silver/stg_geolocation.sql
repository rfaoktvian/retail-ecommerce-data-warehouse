-- Silver: geolocation
-- Cleaning KHUSUS: source asli (bronze) punya BANYAK baris duplikat per zip_code_prefix
-- (satu prefix zip bisa muncul ribuan kali dengan lat/lng sedikit berbeda, hasil GPS crowdsource).
-- Untuk dipakai sebagai dimension nanti (1 baris = 1 zip code), kita agregasi:
-- ambil rata-rata lat/lng, dan ambil salah satu nilai city/state yang representatif.
 
select
    cast(geolocation_zip_code_prefix as string) as zip_code_prefix,
    avg(geolocation_lat) as latitude,
    avg(geolocation_lng) as longitude,
    any_value(lower(trim(geolocation_city))) as city,
    any_value(upper(trim(geolocation_state))) as state
 
from {{ source('bronze', 'csv_geolocation') }}
where geolocation_zip_code_prefix is not null
group by geolocation_zip_code_prefix
 