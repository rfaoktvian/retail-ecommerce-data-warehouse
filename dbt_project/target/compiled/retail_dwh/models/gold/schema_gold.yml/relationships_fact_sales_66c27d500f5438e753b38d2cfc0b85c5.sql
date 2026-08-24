
    
    

with child as (
    select customer_key as from_field
    from `qwiklabs-gcp-03-018d48a9d681`.`gold`.`fact_sales`
    where customer_key is not null
),

parent as (
    select customer_key as to_field
    from `qwiklabs-gcp-03-018d48a9d681`.`gold`.`dim_customers`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


