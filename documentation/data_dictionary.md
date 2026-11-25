# Data Dictionary & Metric Definitions

## 1. Source fields (raw file, before cleaning)

| Column | Raw type | Description | Quality notes & handling |
|---|---|---|---|
| `transaction_id` | Text | Unique transaction key | Must be present and unique. 0 blanks, 0 duplicates. Primary key in SQL. |
| `transaction_date` | Text (ISO `YYYY-MM-DD`) | Date of the transaction | 180 rows contain `not_a_date` → **rejected** (`INVALID_DATE`). Valid range 1 Jan 2024 – 26 Sep 2026. |
| `council_name` | Text | One of six fictional councils (Southmoor, Northbridge, Greenvale, Rivermouth, Westhaven, Eastford) | Required. 0 blanks. |
| `department` | Text | Service area (e.g. Adult Social Care, Highways, Housing) | Required. 0 blanks. |
| `spend_category` | Text | Type of spend (e.g. Staffing, Maintenance, Grants, Technology) | No issues found. |
| `supplier_name` | Text | Supplier paid | 650 blanks in raw (646 in accepted rows). **Kept**, labelled `Not recorded`, flagged. |
| `description` | Text | Narrative of the transaction | No issues found. |
| `actual_spend_gbp` | Numeric | Actual amount in GBP | 250 negative values → **review** (`NEGATIVE_SPEND`). High-value tail: top 1% above ~£334k (max £449,980). |
| `budget_amount_gbp` | Numeric | Budgeted amount in GBP; denominator for variance | No zero or negative values; safe division still applied. |
| `spend_type` | Text | Revenue or Capital | No issues found. |
| `payment_status` | Text | Paid, Approved, Pending, Under Review, Cancelled | 300 rows of `"paid "` (lower case + trailing space) → trimmed and mapped to `Paid`. |
| `procurement_method` | Text | Competitive Tender, Direct Award, Framework, Grant, Purchase Order | No issues found. |
| `funding_source` | Text | General Fund, Capital Programme, Housing Fund, Public Health Grant | No issues found. |
| `currency` | Text | Currency code | Must be `GBP` (hard failure otherwise). All rows GBP. |

## 2. Fields added in Python

| Column | Type | Definition |
|---|---|---|
| `date_clean` (SQL: `transaction_date`) | Date | `transaction_date` converted strictly with format `%Y-%m-%d`; failures become blank and are rejected. |
| `missing_supplier_flag` | Integer 0/1 | 1 if `supplier_name` was blank in the raw file. |
| `Is_Recorded` | Integer 0/1 | 1 if `payment_status` is Paid, Approved, Pending or Under Review; 0 if Cancelled. |
| `Variance_GBP` | Decimal | `actual_spend_gbp − budget_amount_gbp` (positive = overspend, negative = underspend). |
| `Variance_Pct` | Decimal (fraction) | `Variance_GBP ÷ budget_amount_gbp`; blank if budget is 0. Row level only – never average it. |
| `Recorded_Spend` | Decimal | `actual_spend_gbp × Is_Recorded` (Cancelled rows = 0). |
| `Supplier_Share_Of_Council_Pct` | Decimal (fraction) | Supplier's Recorded Spend within the council ÷ council's total Recorded Spend. `Not recorded` is treated as its own supplier group. |
| `reason_code` (exception files) | Text | `INVALID_DATE` (rejected) or `NEGATIVE_SPEND` (review). |
| `source_row` (exception files) | Integer | Line number in the raw CSV (pandas index + 2, because line 1 is the header). |

## 3. Metric definitions (used in SQL views and Power BI)

| Metric | Definition |
|---|---|
| **Recorded Spend** | Sum of `actual_spend_gbp` where status is Paid, Approved, Pending or Under Review. |
| **Budget** | Sum of `budget_amount_gbp` for the same recorded rows (same rule as spend, so the comparison is like-for-like). |
| **Variance £** | Recorded Spend − Budget. |
| **Variance %** | Variance £ ÷ Budget, calculated from **totals** (not an average of row percentages); `NULLIF` protects against zero budget. |
| **Paid / Pending Spend** | Sum of `actual_spend_gbp` where status = Paid / Pending. |
| **Cancelled Spend** | Sum of `actual_spend_gbp` where status = Cancelled (reported separately, excluded from Recorded Spend). |
| **Supplier Share** | Supplier's Recorded Spend ÷ council's Recorded Spend. |
| **Direct Award Share** | Recorded Spend with `procurement_method = 'Direct Award'` ÷ council's Recorded Spend. |
| **Not Recorded Share** | Recorded Spend with `supplier_name = 'Not recorded'` ÷ council's Recorded Spend. |
| **Missing Supplier %** | Rows with `missing_supplier_flag = 1` ÷ all rows. |
| **Accepted / Rejected / Review rows** | Row counts from the Python run, stored in `council.load_audit`. |
| **Financial Year** | UK financial year, April to March (e.g. FY 2025/26 = 1 Apr 2025 – 31 Mar 2026). FY 2023/24 (Jan–Mar 2024 only) and FY 2026/27 (Apr–Sep 2026 only) are partial. |

## 4. Exception rules

| Rule | Type | Rows | Action |
|---|---|---|---|
| Invalid / unparseable date | Hard failure | 180 | Rejected file |
| Missing or duplicate `transaction_id` | Hard failure | 0 | Rejected file (pipeline stops if found) |
| Missing council or department | Hard failure | 0 | Rejected file (pipeline stops if found) |
| Currency not GBP | Hard failure | 0 | Rejected file (pipeline stops if found) |
| Non-numeric spend | Hard failure | 0 | Rejected file (pipeline stops if found) |
| Negative spend | Review warning | 250 | Review file – a person decides (refund, correction or error) |
| Missing supplier | Quality warning | 646 accepted | Kept, labelled `Not recorded`, flagged |
