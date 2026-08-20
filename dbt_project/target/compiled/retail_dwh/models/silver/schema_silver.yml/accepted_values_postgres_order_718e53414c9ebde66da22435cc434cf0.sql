
    
    

with all_values as (

    select
        payment_type as value_field,
        count(*) as n_records

    from `qwiklabs-gcp-04-05c5517686d1`.`silver`.`postgres_order_payments`
    group by payment_type

)

select *
from all_values
where value_field not in (
    'credit_card','boleto','voucher','debit_card','unknown'
)


