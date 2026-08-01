"""Generates synthetic climate-hardware financing data (customers, installers,
loans, payments) for the dbt demo. Not real company data -- sample/synthetic
data only, used to build and test a realistic warehouse model."""
import csv
import random
from datetime import date, timedelta

random.seed(42)
OUT = "seeds"

HARDWARE_TYPES = ["solar", "battery", "heat_pump", "ev_charger"]
COUNTRIES = ["DE", "FR", "NL", "AT", "ES"]
RISK_SEGMENTS = ["low", "medium", "high"]
# risk segment -> (late_payment_prob, default_prob)
RISK_PROFILE = {
    "low": (0.04, 0.01),
    "medium": (0.10, 0.04),
    "high": (0.22, 0.12),
}

def rand_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, max(delta, 0)))

# ---------- installers ----------
installers = []
for i in range(1, 19):
    installers.append({
        "installer_id": f"INS{i:03d}",
        "installer_name": f"{random.choice(['Sonnen','Nord','Alpen','Rhein','Vento','Terra'])} {random.choice(['Energy','Solar','Systems','Technik','Haus'])} {i}",
        "hardware_type": random.choice(HARDWARE_TYPES),
        "country": random.choice(COUNTRIES),
        "signup_date": rand_date(date(2023, 1, 1), date(2024, 6, 1)).isoformat(),
    })

with open(f"{OUT}/raw_installers.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(installers[0].keys()))
    w.writeheader()
    w.writerows(installers)

# ---------- customers ----------
customers = []
for i in range(1, 321):
    customers.append({
        "customer_id": f"CUST{i:04d}",
        "signup_date": rand_date(date(2021, 1, 1), date(2025, 6, 1)).isoformat(),
        "country": random.choice(COUNTRIES),
        "risk_segment": random.choices(RISK_SEGMENTS, weights=[0.55, 0.32, 0.13])[0],
    })

with open(f"{OUT}/raw_customers.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(customers[0].keys()))
    w.writeheader()
    w.writerows(customers)

# ---------- loans ----------
loans = []
loan_id_counter = 1
for cust in customers:
    n_loans = random.choices([1, 2], weights=[0.85, 0.15])[0]
    for _ in range(n_loans):
        installer = random.choice(installers)
        origination = rand_date(
            date.fromisoformat(cust["signup_date"]),
            min(date.fromisoformat(cust["signup_date"]) + timedelta(days=120), date(2026, 7, 1)),
        )
        term = random.choice([24, 36, 48, 60, 84])
        principal = round(random.uniform(3500, 28000), 2)
        rate = round(random.uniform(3.9, 8.9), 2)
        loans.append({
            "loan_id": f"LOAN{loan_id_counter:05d}",
            "customer_id": cust["customer_id"],
            "installer_id": installer["installer_id"],
            "hardware_type": installer["hardware_type"],
            "principal_amount": principal,
            "term_months": term,
            "interest_rate_pct": rate,
            "origination_date": origination.isoformat(),
            "risk_segment": cust["risk_segment"],
        })
        loan_id_counter += 1

with open(f"{OUT}/raw_loans.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(loans[0].keys()))
    w.writeheader()
    w.writerows(loans)

# ---------- payments ----------
TODAY = date(2026, 8, 1)
payments = []
payment_id_counter = 1
for loan in loans:
    origination = date.fromisoformat(loan["origination_date"])
    monthly_amount = round(loan["principal_amount"] / loan["term_months"], 2)
    late_prob, default_prob = RISK_PROFILE[loan["risk_segment"]]
    defaulted_at = None
    if random.random() < default_prob:
        defaulted_at = random.randint(2, loan["term_months"])

    for installment_no in range(1, loan["term_months"] + 1):
        due_date = origination + timedelta(days=30 * installment_no)
        if due_date > TODAY:
            status = "upcoming"
            paid_date = ""
            amount_paid = ""
        elif defaulted_at and installment_no >= defaulted_at:
            status = "missed"
            paid_date = ""
            amount_paid = "0.00"
        elif random.random() < late_prob:
            status = "late"
            paid_date = (due_date + timedelta(days=random.randint(3, 21))).isoformat()
            amount_paid = f"{monthly_amount:.2f}"
        else:
            status = "paid"
            paid_date = (due_date - timedelta(days=random.randint(0, 3))).isoformat()
            amount_paid = f"{monthly_amount:.2f}"

        payments.append({
            "payment_id": f"PAY{payment_id_counter:06d}",
            "loan_id": loan["loan_id"],
            "installment_number": installment_no,
            "due_date": due_date.isoformat(),
            "amount_due": f"{monthly_amount:.2f}",
            "paid_date": paid_date,
            "amount_paid": amount_paid,
            "status": status,
        })
        payment_id_counter += 1

with open(f"{OUT}/raw_payments.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(payments[0].keys()))
    w.writeheader()
    w.writerows(payments)

print(f"installers={len(installers)} customers={len(customers)} loans={len(loans)} payments={len(payments)}")
