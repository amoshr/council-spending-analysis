CREATE TABLE IF NOT EXISTS council.load_audit (
    run_id           SERIAL       PRIMARY KEY,
    source_filename  VARCHAR(200) NOT NULL,
    started_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
    ended_at         TIMESTAMP,
    input_rows       INTEGER,
    accepted_rows    INTEGER,
    rejected_rows    INTEGER,
    review_rows      INTEGER,
    staged_rows      INTEGER,
    final_rows       INTEGER,
    status           VARCHAR(20)  NOT NULL DEFAULT 'STARTED'
);

CREATE TABLE IF NOT EXISTS council.validation_log (
    run_id       INTEGER      NOT NULL REFERENCES council.load_audit(run_id),
    check_name   VARCHAR(100) NOT NULL,
    failed_rows  INTEGER      NOT NULL,
    passed       BOOLEAN      NOT NULL,
    checked_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);
