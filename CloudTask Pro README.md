# CloudTask Pro – SaaS Revenue & Churn Analysis (MySQL)

## Business Context

CloudTask Pro is a B2B SaaS company selling project management software. It has grown from 0 to 600 customers since 2022. Revenue is growing, but the board is concerned about a high churn rate. Ahead of a board meeting, the CFO wants to understand:

1. Monthly churn trends
2. Which customer segments are most at risk
3. Unit economics: MRR per customer, customer acquisition cost (CAC) and lifetime value (CLV)

As a business analyst, I used SQL to analyze subscription data, monthly recurring revenue (MRR) and customer behavior to identify churn drivers and at-risk customers.

## Datasets

| File | Rows | Description |
|---|---:|---|
| `subscriptions.csv` | 600 | One row per customer: plan, billing cycle, industry, company size, seats, monthly revenue, acquisition channel, region, signup and churn dates, churn reason, support tickets, NPS score, feature usage %, upgrade flag |
| `monthly_revenue.csv` | 48 | Monthly summary (2022-01 to 2025-12): active customers, new and churned customers, monthly churn rate, total MRR, average revenue per customer, CAC |

## Project Structure

```
├── README.md
├── saas_revenue_churn_analysis.sql   -- all queries with comments
└── data/
    ├── subscriptions.csv
    └── monthly_revenue.csv
```

The SQL script is organized into four sections:

1. **EDA & data validation** – checking how derived columns were calculated, reconciling customer counts, checking duplicates, missing values and category values
2. **Churn analysis** – share of customers ever churned by plan, billing cycle, acquisition channel, company size; top churn reasons
3. **Unit economics** – customer lifespan and estimated revenue per customer by plan
4. **At-risk indicators** – feature usage, NPS and churn; export list of at-risk active customers

## SQL Techniques Used

- Conditional aggregation (`SUM(IF(...))`)
- `GROUP BY`, `WITH ROLLUP` subtotals
- Subqueries and CTEs (including chained CTEs)
- Window function `LEAD()` for month-to-month reconciliation
- Date functions: `DATEDIFF()`, `TIMESTAMPDIFF()`
- `CASE` expressions, `FLOOR()` bucketing and `CONCAT()` labels

## Key Findings

### Data validation
- `monthly_churn_rate_pct` = churned customers / customers at the **start** of the month; `avg_revenue_per_customer` = total MRR / active customers.
- **Customer counts do not reconcile**: in several months, start customers + new − churned ≠ next month's start count (e.g. August 2022: 57 + 18 − 6 = 69, but September reports 67). This is documented as a data limitation.
- Each customer appears once. Non-churned customers have an empty string (not `NULL`) in `churn_date` and `churn_reason`.

### Churn
- **52.17%** of all customers have churned (313 of 600).
- **Plan:** Starter has the highest churned share – 153 of 217 (70.51%) – and the largest number of churned customers. Enterprise is lowest (22.00%).
- **Billing cycle:** monthly payers churned more than annual payers (60.5% vs 40.3%).
- **Acquisition channel:** Referral has the highest churned share (61.29%); Direct Sales the lowest (39.3%).
- **Company size:** 500+ has the highest share (63.16%), but it is the smallest group (38 customers), so this is interpreted cautiously. 11–50 has the most churned customers (93).
- **Top churn reasons:** Budget Cuts (53), Price Too High (51), Company Closed (48). "Price Too High" is the reason the company can most directly influence – most of these customers were on the Starter plan (29/51) and paid monthly (37/51).

### Unit economics
- Customer lifespan was measured in days and converted to months (÷ 30.44), because `TIMESTAMPDIFF(MONTH, ...)` discards partial months.
- Revenue per customer was estimated as `AVG(monthly_revenue × lifespan)`, averaging customer-level estimates rather than multiplying two averages.
- **Average estimated lifetime revenue per churned customer:** Enterprise ≈ 30,580; Business ≈ 23,243; Professional ≈ 5,470; Starter ≈ 1,453.
- **Average estimated observed-to-date revenue per customer (all customers, cutoff 2025-12-31):** Enterprise is highest (≈ 65,773), Starter lowest (≈ 1,852).
- Churned Starter customers form the largest churned group but have the lowest average estimated revenue per customer.

### At-risk indicators
- Churned customers have much lower average feature usage (27.45% vs 55.02%) and lower NPS responses (3.04 vs 5.81).
- No churn was observed in feature usage buckets of 60% and above.
- **All churned customers are NPS detractors (0–6).**
- Combined view:

| Feature usage | NPS group | Customers | Churned | Share churned |
|---|---|---:|---:|---:|
| Below 50% | Detractor | 376 | 308 | 81.91% |
| 50% or above | Detractor | 94 | 5 | 5.32% |
| Below 50% | Passive / Promoter | 64 | 0 | 0.00% |
| 50% or above | Passive / Promoter | 66 | 0 | 0.00% |

- 132 active customers have feature usage below 50%. Using the combined rule (**usage < 50% AND NPS 0–6**), **68 active customers** are flagged for retention review. The final query exports this list.

## Limitations

- Monthly customer counts do not fully reconcile, so monthly figures are used for descriptive trends only.
- The observation cutoff of **2025-12-31** is assumed (latest available date), not confirmed by the data source.
- Revenue estimates use a single recorded `monthly_revenue` value per customer; actual invoices, refunds, plan changes (`upgraded`) and gross margin are not available. These are revenue proxies, not true CLV.
- Active customers' lifespans are unfinished (right-censored), so their revenue covers only their time so far.
- Churn shares are "share ever churned", not monthly churn rates, and are not adjusted for signup cohort or time at risk.
- CAC is only available company-wide per month, so a plan-level CLV:CAC ratio could not be calculated reliably.
- It is unknown when NPS and feature usage were measured; the at-risk flag is an exploratory rule, not a validated prediction.

## How to Run

1. Create a MySQL database (MySQL 8.0+ is required for window functions).
2. Import `subscriptions.csv` and `monthly_revenue.csv` as tables named `subscriptions` and `monthly_revenue` (e.g. with the MySQL Workbench Table Data Import Wizard).
3. Run `saas_revenue_churn_analysis.sql` section by section.
