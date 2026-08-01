select
    p.payment_id,
    p.loan_id,
    l.customer_id,
    l.installer_id,
    l.hardware_type,
    l.risk_segment,
    p.installment_number,
    p.due_date,
    p.amount_due,
    p.paid_date,
    p.amount_paid,
    p.status,
    p.is_delinquent_event,
    p.days_paid_after_due
from {{ ref('stg_payments') }} p
left join {{ ref('stg_loans') }} l on p.loan_id = l.loan_id
