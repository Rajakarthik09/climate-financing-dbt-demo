# climate-financing-dbt-demo

A small, fully working dbt project modeling a climate-hardware installment
lender (solar / battery / heat pump / EV charger financing) — built to close
a specific, real gap: no prior hands-on dbt experience, ahead of applying to
a data engineering role at a climate-fintech.

**This is sample/synthetic data, not real company data.** `generate_data.py`
produces realistic-looking but fabricated customers, installers, loans, and
payments with a deliberately built-in risk gradient (`high` risk-segment
loans default ~10x more often than `low`), so the resulting risk mart has an
actual signal to show, not just plumbing.

## Stack

- **dbt-core** + **dbt-duckdb** — no cloud account, no credentials, no cost.
  DuckDB is an in-process warehouse; the same models would run against
  Snowflake or BigQuery by swapping the adapter in `profiles.yml`.
- Raw data loaded via `dbt seed` (not external sources) since this is
  self-contained sample data.

## Project structure

```
seeds/            raw_customers, raw_installers, raw_loans, raw_payments (+ schema.yml tests)
models/staging/   stg_* — typed, cleaned 1:1 views over the seeds
models/marts/     dim_customers, dim_installers, fct_loans, fct_payments,
                   mart_portfolio_risk (the business-facing output)
tests/            2 custom singular tests (installment-count reconciliation,
                   outstanding-balance sanity check)
```

`mart_portfolio_risk` aggregates default and delinquency rate by risk
segment and hardware type — the kind of table a Risk or Finance stakeholder
would actually query.

## How to run it

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install dbt-core dbt-duckdb
python3 generate_data.py          # (re)generates the seed CSVs
export DBT_PROFILES_DIR="$(pwd)"
dbt seed
dbt run
dbt test                          # 40 tests: not_null, unique, relationships,
                                   # accepted_values, plus 2 custom SQL tests
dbt docs generate && dbt docs serve   # browsable lineage graph + column docs
```

## A real bug hit and fixed while building this

`dbt-duckdb` auto-infers seed column types from the CSV content — so a
mostly-date column with some blank cells lands as native `DATE` with blanks
already converted to `NULL`, not `VARCHAR`. The staging models were
originally written defensively for a `VARCHAR` source (`nullif(paid_date,
'')`), which is how a real warehouse's raw/staging layer usually lands data.
Against an already-typed DuckDB column, `nullif(date_col, '')` forces DuckDB
to cast the empty string literal `''` to `DATE` to do the comparison, which
throws (`invalid date field format: ""`). Fixed by explicitly casting to
`varchar` first (`nullif(cast(paid_date as varchar), '')`) so the empty-string
check is well-defined regardless of what type the source column actually
carries — the more portable fix, and the one that would also survive a
switch to a real warehouse.
