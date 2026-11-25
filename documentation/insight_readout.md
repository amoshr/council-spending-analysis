# Insight Readout

**Scope:** 49,570 accepted transactions, six fictional councils, 1 Jan 2024 – 26 Sep 2026.
**Rule:** Recorded Spend = Paid + Approved + Pending + Under Review (Cancelled excluded).
**Reminder:** all data is synthetic. These findings point to **areas for finance review and data-quality improvement**; they are not evidence of non-compliance or wrongdoing.

---

## 1. Every council is under budget – led by Northbridge and Greenvale

- Recorded spend **£494.7M** against budget **£518.6M**: **£23.9M (4.6%) underspent**.
- All six councils are under budget: Northbridge −5.6% (−£5.0M), Greenvale −5.1% (−£4.3M), Rivermouth lowest at −3.6%.
- By department, **Public Health (−5.9%)**, Highways (−5.6%) and Housing (−5.4%) have the largest gaps; Planning (−2.6%) the smallest.
- Largest single gap: **Greenvale – Housing – Grants, −£447k (−19.5%)**.
- There are still overspend pockets, e.g. **Northbridge – Adult Social Care – Maintenance, +£230k (+17.7%)**.

**Recommendation:** Finance review the top 10 under- and overspend cells in View 1, starting with Greenvale Housing.
**Limitations:** Budget is held per transaction, not as an annual departmental budget, so underspend may reflect how budgets were allocated rather than real savings. Underspend is not automatically good – it can mean services or grants were not delivered.
**Follow-up questions:** Were Greenvale's housing grants delayed or cancelled? Are budgets re-profiled during the year?

## 2. About half of recorded spend is not yet settled

- **Under Review £124.7M** and **Pending £120.0M**: together **49.5%** of recorded spend has not yet been paid or approved.
- Only **£129.5M (26.2%)** of recorded spend is Paid.

**Recommendation:** Track the ageing of Pending and Under Review items (days since transaction date) and set a target time to decision.
**Limitations:** The dataset has no status-change dates, so we cannot tell how long items have been waiting, or whether "Under Review" means a query or routine checking.
**Follow-up questions:** What is the expected time from transaction to payment? Do any departments hold a much larger share of items under review?

## 3. Cancelled transactions are unusually high

- **9,736 transactions (19.6% of accepted rows)** worth **£122.4M** are Cancelled.
- They are excluded from Recorded Spend but kept in the data and reported separately.

**Recommendation:** Confirm the cancellation reasons with each council; a cancellation rate near 1 in 5 would normally prompt a process review.
**Limitations:** No cancellation reason field exists, and in synthetic data statuses are spread almost evenly (each ~20%), which may not reflect real behaviour.
**Follow-up questions:** Are cancellations duplicates, raised in error, or genuine changes of plan?

## 4. Direct awards vary between councils; supplier concentration is low

- **Direct Award** share of recorded spend ranges from **17.5% (Eastford) to 23.0% (Greenvale)**.
- Each council's **largest supplier** takes only **10.3% – 11.5%** of its recorded spend, close to an even split across the 11 named suppliers (~9% each). No single supplier dominates.

**Recommendation:** Review the justification records for Greenvale's direct awards, since it is 3–6 points above the other councils.
**Limitations:** Direct awards can be fully legitimate (urgent repairs, specialist providers, value below tender thresholds). The data has no contract values, thresholds or award reasons.
**Follow-up questions:** What share of Greenvale's direct awards are emergency spend? Do any direct awards exceed procurement thresholds?

## 5. Data quality is good, with clear, fixable gaps

- **180 rows (0.36%)** rejected for invalid dates; **250 rows (0.5%)** held for review as negative spend.
- **646 accepted rows (1.3%)** have no supplier recorded, worth **0.8% – 2.2%** of each council's recorded spend (highest in Eastford).
- **300 status labels** (`"paid "`) were inconsistent and corrected through a mapping table.
- After cleaning, all 9 SQL validation checks passed and every layer reconciles: 49,570 rows and £494,674,327.33 in Python, staging, final table and views.

**Recommendation:** Make supplier and date mandatory in the source finance system, and use a drop-down list for payment status to stop free-text variants.
**Limitations:** Negative amounts may be legitimate refunds or credit notes; they need a finance decision, not automatic deletion.
**Follow-up questions:** Which system or team creates rows without a supplier? Are the negative amounts refunds, reversals or keying errors?

---

## Reconciliation evidence

| Check | Result |
|---|---|
| 49,570 accepted + 180 rejected + 250 review = 50,000 source rows | ✅ True |
| Python accepted rows = SQL staging = SQL final | ✅ 49,570 each |
| Recorded Spend: Python = staging = final = Views 1–3 | ✅ £494,674,327.33 |
| Power BI FY 2025/26 Recorded Spend vs SQL | ✅ £175.3M vs £175,304,037.51 |
| SQL validation checks (`council.validation_log`) | ✅ 9 of 9 passed |
| Load audit (`council.load_audit`) | ✅ Status SUCCESS |

## Partial periods

FY 2023/24 covers only Jan–Mar 2024 and FY 2026/27 only Apr–26 Sep 2026; September 2026 is missing its last four days. Do not compare these periods with full years or months without adjusting.
