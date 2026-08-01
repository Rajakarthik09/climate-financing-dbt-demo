-- Note: DuckDB's seed loader auto-infers column types from the CSV content,
-- so paid_date/amount_paid already land typed (DATE/DOUBLE) with blanks as
-- NULL. Casting to varchar first before the nullif/empty-string check keeps
-- this robust regardless of how the source lands (e.g. a real warehouse
-- staging layer that lands everything as VARCHAR instead).

with source as (
    select * from {{ ref('raw_payments') }}
)

select
    payment_id,
    loan_id,
    cast(installment_number as integer) as installment_number,
    cast(due_date as date) as due_date,
    cast(amount_due as decimal(12, 2)) as amount_due,
    try_cast(nullif(cast(paid_date as varchar), '') as date) as paid_date,
    try_cast(nullif(cast(amount_paid as varchar), '') as decimal(12, 2)) as amount_paid,
    status,
    case when status in ('late', 'missed') then true else false end as is_delinquent_event,
    case
        when status = 'late' then
            date_diff('day', cast(due_date as date), try_cast(nullif(cast(paid_date as varchar), '') as date))
        else null
    end as days_paid_after_due
from source
