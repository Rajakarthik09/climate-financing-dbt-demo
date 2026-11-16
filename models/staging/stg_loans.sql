with source as (
    select * from {{ ref('raw_loans') }}
)

select
    loan_id,
    customer_id,
    installer_id,
    hardware_type,
    cast(principal_amount as {{ money_type() }}) as principal_amount,
    cast(term_months as {{ dbt.type_int() }}) as term_months,
    cast(interest_rate_pct as {{ rate_type() }}) as interest_rate_pct,
    cast(origination_date as date) as origination_date,
    risk_segment
from source
