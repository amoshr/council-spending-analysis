DO $$
DECLARE
    -- counts from Python's quality_summary.csv
    v_input     INTEGER := 50000;
    v_accepted  INTEGER := 49570;
    v_rejected  INTEGER := 180;
    v_review    INTEGER := 250;
    v_run_id    INTEGER;
    v_staged    INTEGER;
    v_final     INTEGER;
    v_failed    INTEGER;
BEGIN
    INSERT INTO council.load_audit (source_filename, input_rows, accepted_rows, rejected_rows, review_rows)
    VALUES ('clean_council_spend.csv', v_input, v_accepted, v_rejected, v_review)
    RETURNING run_id INTO v_run_id;

    SELECT COUNT(*) INTO v_staged FROM council.stg_spend;

    INSERT INTO council.validation_log (run_id, check_name, failed_rows, passed)
    SELECT v_run_id, check_name, failed_rows, failed_rows = 0
    FROM (
        SELECT 'staged_count_matches_python' AS check_name,
               ABS(v_staged - v_accepted) AS failed_rows
        UNION ALL
        SELECT 'reconciles_to_input', ABS(v_accepted + v_rejected + v_review - v_input)
        UNION ALL
        SELECT 'duplicate_transaction_id',
               (SELECT COUNT(*) - COUNT(DISTINCT transaction_id) FROM council.stg_spend)::INTEGER
        UNION ALL
        SELECT 'null_required_fields',
               (SELECT COUNT(*) FROM council.stg_spend
                WHERE transaction_id IS NULL OR transaction_date IS NULL
                   OR council_name IS NULL OR department IS NULL OR currency IS NULL)::INTEGER
        UNION ALL
        SELECT 'negative_spend',
               (SELECT COUNT(*) FROM council.stg_spend WHERE actual_spend_gbp < 0)::INTEGER
        UNION ALL
        SELECT 'non_gbp_currency',
               (SELECT COUNT(*) FROM council.stg_spend WHERE currency <> 'GBP')::INTEGER
        UNION ALL
        SELECT 'invalid_payment_status',
               (SELECT COUNT(*) FROM council.stg_spend
                WHERE payment_status NOT IN ('Paid','Approved','Pending','Under Review','Cancelled'))::INTEGER
        UNION ALL
        SELECT 'date_out_of_range',
               (SELECT COUNT(*) FROM council.stg_spend
                WHERE transaction_date < DATE '2020-01-01' OR transaction_date > CURRENT_DATE)::INTEGER
        UNION ALL
        SELECT 'is_recorded_rule_mismatch',
               (SELECT COUNT(*) FROM council.stg_spend
                WHERE is_recorded <> CASE WHEN payment_status = 'Cancelled' THEN 0 ELSE 1 END)::INTEGER
    ) AS checks;

    SELECT COUNT(*) INTO v_failed
    FROM council.validation_log
    WHERE run_id = v_run_id AND passed = FALSE;

    IF v_failed > 0 THEN
        UPDATE council.load_audit
        SET staged_rows = v_staged, final_rows = 0, ended_at = clock_timestamp(), status = 'FAILED'
        WHERE run_id = v_run_id;
        RAISE NOTICE 'Run %: % check(s) failed - promotion blocked', v_run_id, v_failed;
        RETURN;
    END IF;

    TRUNCATE council.fact_spend;

    INSERT INTO council.fact_spend (
        transaction_id, transaction_date, council_name, department, spend_category,
        supplier_name, description, actual_spend_gbp, budget_amount_gbp, spend_type,
        payment_status, procurement_method, funding_source, currency,
        missing_supplier_flag, is_recorded, variance_gbp, variance_pct,
        recorded_spend_gbp, supplier_share_of_council_pct)
    SELECT
        transaction_id, transaction_date, council_name, department, spend_category,
        supplier_name, description, actual_spend_gbp, budget_amount_gbp, spend_type,
        payment_status, procurement_method, funding_source, currency,
        missing_supplier_flag, is_recorded, variance_gbp, variance_pct,
        recorded_spend_gbp, supplier_share_of_council_pct
    FROM council.stg_spend;

    SELECT COUNT(*) INTO v_final FROM council.fact_spend;

    UPDATE council.load_audit
    SET staged_rows = v_staged, final_rows = v_final, ended_at = clock_timestamp(), status = 'SUCCESS'
    WHERE run_id = v_run_id;

    RAISE NOTICE 'Run %: all checks passed, % rows promoted', v_run_id, v_final;
END $$;