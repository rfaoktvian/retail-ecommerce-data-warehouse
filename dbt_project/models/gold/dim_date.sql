-- dim_date SENGAJA tidak ref() ke tabel manapun — di-generate langsung
-- pakai dbt_utils.date_spine, meng-cover rentang tanggal transaksi Olist (2016-2020)

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2020-12-31' as date)"
    ) }}
)

select
    {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_key,
    date_day as full_date,
    extract(year from date_day) as year,
    extract(quarter from date_day) as quarter,
    extract(month from date_day) as month,
    format_date('%B', date_day) as month_name,
    extract(day from date_day) as day,
    extract(dayofweek from date_day) as day_of_week,
    format_date('%A', date_day) as day_name

from date_spine