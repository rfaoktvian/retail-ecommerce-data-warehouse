
    
    

with all_values as (

    select
        payment_type as value_field,
        count(*) as n_records

    from `qwiklabs-gcp-03-018d48a9d681`.`silver`.`stg_order_payments`
    group by payment_type

)

select *
from all_values
where value_field not in (
    'credit_card','boleto','voucher','debit_card','unknown'
)


