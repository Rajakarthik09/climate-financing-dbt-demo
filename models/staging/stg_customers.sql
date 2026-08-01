with source as (
    select * from {{ ref('raw_customers') }}
)

select
    customer_id,
    cast(signup_date as date) as signup_date,
    country,
    risk_segment
from source
