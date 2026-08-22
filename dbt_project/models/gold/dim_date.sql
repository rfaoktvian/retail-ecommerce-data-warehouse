-- Gold: dim_date
-- Grain: 1 baris = 1 hari kalender
-- Di-generate via dbt_utils.date_spine (tidak ref() ke tabel manapun)
-- Rentang: 2016-01-01 s/d 2020-12-31 (covers seluruh rentang transaksi Olist)

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2020-12-31' as date)"
    ) }}
)

select
    {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_key,

    date_day                                              as full_date,
    extract(year    from date_day)                        as year,
    extract(quarter from date_day)                        as quarter,
    'Q' || cast(extract(quarter from date_day) as string) as quarter_name,
    extract(month   from date_day)                        as month,
    format_date('%B', date_day)                           as month_name,
    format_date('%b', date_day)                           as month_short,
    extract(week    from date_day)                        as week_of_year,
    extract(day     from date_day)                        as day,
    extract(dayofweek from date_day)                      as day_of_week,  -- 1=Sun, 7=Sat (BigQuery)
    format_date('%A', date_day)                           as day_name,
    format_date('%a', date_day)                           as day_short,

    -- Flags analitik
    case
        when extract(dayofweek from date_day) in (1, 7) then true
        else false
    end                                                   as is_weekend,
    case
        when extract(dayofweek from date_day) between 2 and 6 then true
        else false
    end                                                   as is_weekday

from date_spine