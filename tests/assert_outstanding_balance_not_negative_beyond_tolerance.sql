-- Fails if outstanding balance drops meaningfully below zero (small rounding
-- slack allowed for the synthetic-data generator).
select loan_id, outstanding_balance
from {{ ref('fct_loans') }}
where outstanding_balance < -5.00
