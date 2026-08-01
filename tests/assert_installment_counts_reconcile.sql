-- Fails if a loan's installment buckets don't add up to its scheduled count.
select
    loan_id,
    scheduled_installments,
    paid_installments + late_installments + missed_installments + upcoming_installments as summed_installments
from {{ ref('fct_loans') }}
where scheduled_installments != paid_installments + late_installments + missed_installments + upcoming_installments
