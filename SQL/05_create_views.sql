-- View 1: Spend vs Budget variance register
CREATE OR REPLACE VIEW council.vw_variance_register AS
SELECT
    council_name,
    department,
    spend_category,
    SUM(CASE WHEN is_recorded = 1 THEN actual_spend_gbp ELSE 0 END)  AS recorded_spend_gbp,
    SUM(CASE WHEN is_recorded = 1 THEN budget_amount_gbp ELSE 0 END) AS budget_gbp,
    SUM(CASE WHEN is_recorded = 1 THEN actual_spend_gbp ELSE 0 END)
      - SUM(CASE WHEN is_recorded = 1 THEN budget_amount_gbp ELSE 0 END) AS variance_gbp,
    ROUND(
      (SUM(CASE WHEN is_recorded = 1 THEN actual_spend_gbp ELSE 0 END)
       - SUM(CASE WHEN is_recorded = 1 THEN budget_amount_gbp ELSE 0 END))
      / NULLIF(SUM(CASE WHEN is_recorded = 1 THEN budget_amount_gbp ELSE 0 END), 0), 4) AS variance_pct,
    SUM(is_recorded) AS transaction_count
FROM council.fact_spend
GROUP BY council_name, department, spend_category;

-- View 2: Monthly spend movement
CREATE OR REPLACE VIEW council.vw_monthly_spend AS
SELECT
    DATE_TRUNC('month', transaction_date)::DATE AS spend_month,
    council_name,
    SUM(CASE WHEN is_recorded = 1 THEN actual_spend_gbp ELSE 0 END)          AS recorded_spend_gbp,
    SUM(CASE WHEN payment_status = 'Paid' THEN actual_spend_gbp ELSE 0 END)    AS paid_spend_gbp,
    SUM(CASE WHEN payment_status = 'Pending' THEN actual_spend_gbp ELSE 0 END) AS pending_spend_gbp
FROM council.fact_spend
GROUP BY DATE_TRUNC('month', transaction_date)::DATE, council_name;

-- View 3: Supplier & procurement concentration
CREATE OR REPLACE VIEW council.vw_supplier_concentration AS
SELECT
    s.council_name,
    s.supplier_name,
    s.procurement_method,
    s.funding_source,
    s.recorded_spend_gbp,
    ROUND(s.recorded_spend_gbp / NULLIF(t.council_recorded_gbp, 0), 4) AS share_of_council_pct,
    ROUND(t.not_recorded_gbp   / NULLIF(t.council_recorded_gbp, 0), 4) AS council_not_recorded_share_pct,
    ROUND(t.direct_award_gbp   / NULLIF(t.council_recorded_gbp, 0), 4) AS council_direct_award_share_pct
FROM (
    SELECT council_name, supplier_name, procurement_method, funding_source,
           SUM(CASE WHEN is_recorded = 1 THEN actual_spend_gbp ELSE 0 END) AS recorded_spend_gbp
    FROM council.fact_spend
    GROUP BY council_name, supplier_name, procurement_method, funding_source
) AS s
JOIN (
    SELECT council_name,
           SUM(CASE WHEN is_recorded = 1 THEN actual_spend_gbp ELSE 0 END) AS council_recorded_gbp,
           SUM(CASE WHEN is_recorded = 1 AND supplier_name = 'Not recorded'
                    THEN actual_spend_gbp ELSE 0 END) AS not_recorded_gbp,
           SUM(CASE WHEN is_recorded = 1 AND procurement_method = 'Direct Award'
                    THEN actual_spend_gbp ELSE 0 END) AS direct_award_gbp
    FROM council.fact_spend
    GROUP BY council_name
) AS t
  ON s.council_name = t.council_name;

-- View 4: Payment status & data completeness
CREATE OR REPLACE VIEW council.vw_status_completeness AS
SELECT
    f.council_name,
    COUNT(*) AS transactions,
    SUM(actual_spend_gbp) AS total_value_gbp,
    SUM(CASE WHEN payment_status = 'Paid'         THEN 1 ELSE 0 END) AS paid_count,
    SUM(CASE WHEN payment_status = 'Approved'     THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN payment_status = 'Pending'      THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN payment_status = 'Under Review' THEN 1 ELSE 0 END) AS under_review_count,
    SUM(CASE WHEN payment_status = 'Cancelled'    THEN 1 ELSE 0 END) AS cancelled_count,
    ROUND(SUM(CASE WHEN payment_status = 'Paid'         THEN actual_spend_gbp ELSE 0 END) / NULLIF(SUM(actual_spend_gbp), 0), 4) AS paid_value_share,
    ROUND(SUM(CASE WHEN payment_status = 'Approved'     THEN actual_spend_gbp ELSE 0 END) / NULLIF(SUM(actual_spend_gbp), 0), 4) AS approved_value_share,
    ROUND(SUM(CASE WHEN payment_status = 'Pending'      THEN actual_spend_gbp ELSE 0 END) / NULLIF(SUM(actual_spend_gbp), 0), 4) AS pending_value_share,
    ROUND(SUM(CASE WHEN payment_status = 'Under Review' THEN actual_spend_gbp ELSE 0 END) / NULLIF(SUM(actual_spend_gbp), 0), 4) AS under_review_value_share,
    ROUND(SUM(CASE WHEN payment_status = 'Cancelled'    THEN actual_spend_gbp ELSE 0 END) / NULLIF(SUM(actual_spend_gbp), 0), 4) AS cancelled_value_share,
    ROUND(SUM(missing_supplier_flag)::DECIMAL / NULLIF(COUNT(*), 0), 4) AS missing_supplier_pct,
    a.rejected_rows AS load_rejected_rows,
    a.review_rows   AS load_review_rows
FROM council.fact_spend AS f
CROSS JOIN (
    SELECT rejected_rows, review_rows
    FROM council.load_audit
    WHERE status = 'SUCCESS'
    ORDER BY run_id DESC
    LIMIT 1
) AS a
GROUP BY f.council_name, a.rejected_rows, a.review_rows;
