select
    customer_id,
    signup_date,
    country,
    risk_segment
from {{ ref('stg_customers') }}
