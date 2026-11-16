-- Note: DuckDB's seed loader auto-infers column types from the CSV content,
-- so paid_date/amount_paid already land typed (DATE/DOUBLE) with blanks as
-- NULL. Casting to varchar first before the nullif/empty-string check keeps
-- this robust regardless of how the source lands (e.g. a real warehouse
-- staging layer that lands everything as VARCHAR instead).
-- dbt's cross-database macros (safe_cast, type_string, datediff) keep the
-- same model valid on both DuckDB and BigQuery.

with source as (
    select * from {{ ref('raw_payments') }}
)

select
    payment_id,
    loan_id,
    cast(installment_number as {{ dbt.type_int() }}) as installment_number,
    cast(due_date as date) as due_date,
    cast(amount_due as {{ money_type() }}) as amount_due,
    {{ dbt.safe_cast("nullif(cast(paid_date as " ~ dbt.type_string() ~ "), '')", "date") }} as paid_date,
    {{ dbt.safe_cast("nullif(cast(amount_paid as " ~ dbt.type_string() ~ "), '')", money_type()) }} as amount_paid,
    status,
    case when status in ('late', 'missed') then true else false end as is_delinquent_event,
    case
        when status = 'late' then
            {{ dbt.datediff("cast(due_date as date)", dbt.safe_cast("nullif(cast(paid_date as " ~ dbt.type_string() ~ "), '')", "date"), "day") }}
        else null
    end as days_paid_after_due
from source
