-- Gold: dim_date
-- Grain: 1 baris = 1 hari kalender
-- Di-generate via dbt_utils.date_spine (tidak ref() ke tabel manapun)
-- Rentang: 2016-01-01 s/d 2020-12-31 (covers seluruh rentang transaksi Olist)

with date_spine as (
    





with rawdata as (

    

    

    with p as (
        select 0 as generated_number union all select 1
    ), unioned as (

    select

    
    p0.generated_number * power(2, 0)
     + 
    
    p1.generated_number * power(2, 1)
     + 
    
    p2.generated_number * power(2, 2)
     + 
    
    p3.generated_number * power(2, 3)
     + 
    
    p4.generated_number * power(2, 4)
     + 
    
    p5.generated_number * power(2, 5)
     + 
    
    p6.generated_number * power(2, 6)
     + 
    
    p7.generated_number * power(2, 7)
     + 
    
    p8.generated_number * power(2, 8)
     + 
    
    p9.generated_number * power(2, 9)
     + 
    
    p10.generated_number * power(2, 10)
    
    
    + 1
    as generated_number

    from

    
    p as p0
     cross join 
    
    p as p1
     cross join 
    
    p as p2
     cross join 
    
    p as p3
     cross join 
    
    p as p4
     cross join 
    
    p as p5
     cross join 
    
    p as p6
     cross join 
    
    p as p7
     cross join 
    
    p as p8
     cross join 
    
    p as p9
     cross join 
    
    p as p10
    
    

    )

    select *
    from unioned
    where generated_number <= 1826
    order by generated_number



),

all_periods as (

    select (
        

        datetime_add(
            cast( cast('2016-01-01' as date) as datetime),
        interval row_number() over (order by generated_number) - 1 day
        )


    ) as date_day
    from rawdata

),

filtered as (

    select *
    from all_periods
    where date_day <= cast('2020-12-31' as date)

)

select * from filtered


)

select
    to_hex(md5(cast(coalesce(cast(date_day as string), '_dbt_utils_surrogate_key_null_') as string))) as date_key,

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