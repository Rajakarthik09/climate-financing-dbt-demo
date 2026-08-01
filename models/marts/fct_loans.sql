with loans as (
    select * from {{ ref('stg_loans') }}
),

payment_agg as (
    select
        loan_id,
        count(*) as scheduled_installments,
        sum(case when status = 'paid' then 1 else 0 end) as paid_installments,
        sum(case when status = 'late' then 1 else 0 end) as late_installments,
        sum(case when status = 'missed' then 1 else 0 end) as missed_installments,
        sum(case when status = 'upcoming' then 1 else 0 end) as upcoming_installments,
        sum(coalesce(amount_paid, 0)) as total_paid,
        max(is_delinquent_event) as has_any_delinquency
    from {{ ref('stg_payments') }}
    group by loan_id
)

select
    loans.loan_id,
    loans.customer_id,
    loans.installer_id,
    loans.hardware_type,
    loans.risk_segment,
    loans.principal_amount,
    loans.term_months,
    loans.interest_rate_pct,
    loans.origination_date,
    payment_agg.scheduled_installments,
    payment_agg.paid_installments,
    payment_agg.late_installments,
    payment_agg.missed_installments,
    payment_agg.upcoming_installments,
    round(payment_agg.total_paid, 2) as total_paid,
    round(loans.principal_amount - payment_agg.total_paid, 2) as outstanding_balance,
    payment_agg.has_any_delinquency,
    case when payment_agg.missed_installments >= 2 then true else false end as is_defaulted
from loans
left join payment_agg on loans.loan_id = payment_agg.loan_id
