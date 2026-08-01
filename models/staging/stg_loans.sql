with source as (
    select * from {{ ref('raw_loans') }}
)

select
    loan_id,
    customer_id,
    installer_id,
    hardware_type,
    cast(principal_amount as decimal(12, 2)) as principal_amount,
    cast(term_months as integer) as term_months,
    cast(interest_rate_pct as decimal(5, 2)) as interest_rate_pct,
    cast(origination_date as date) as origination_date,
    risk_segment
from source
