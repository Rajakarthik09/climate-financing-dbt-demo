-- Portfolio-level risk view: default and delinquency rates cut by risk
-- segment, hardware type, and installer. Built for a Risk/Finance
-- stakeholder audience, not an engineering one.

with loans as (
    select * from {{ ref('fct_loans') }}
),

by_segment as (
    select
        risk_segment,
        hardware_type,
        count(*) as loan_count,
        sum(principal_amount) as total_originated,
        sum(outstanding_balance) as total_outstanding,
        sum(case when is_defaulted then 1 else 0 end) as defaulted_loans,
        sum(case when has_any_delinquency then 1 else 0 end) as ever_delinquent_loans,
        round(
            100.0 * sum(case when is_defaulted then 1 else 0 end) / nullif(count(*), 0), 2
        ) as default_rate_pct,
        round(
            100.0 * sum(case when has_any_delinquency then 1 else 0 end) / nullif(count(*), 0), 2
        ) as delinquency_rate_pct
    from loans
    group by risk_segment, hardware_type
)

select * from by_segment
order by risk_segment, hardware_type
