CREATE SCHEMA IF NOT EXISTS council;

DROP TABLE IF EXISTS council.stg_spend;
CREATE TABLE council.stg_spend (
    transaction_id                 VARCHAR(20),
    transaction_date_raw           VARCHAR(20),
    council_name                   VARCHAR(100),
    department                     VARCHAR(100),
    spend_category                 VARCHAR(100),
    supplier_name                  VARCHAR(150),
    description                    VARCHAR(255),
    actual_spend_gbp               DECIMAL(14,2),
    budget_amount_gbp              DECIMAL(14,2),
    spend_type                     VARCHAR(50),
    payment_status                 VARCHAR(30),
    procurement_method             VARCHAR(50),
    funding_source                 VARCHAR(100),
    currency                       CHAR(3),
    transaction_date               DATE,
    missing_supplier_flag          SMALLINT,
    is_recorded                    SMALLINT,
    variance_gbp                   DECIMAL(14,2),
    variance_pct                   DECIMAL(12,6),
    recorded_spend_gbp             DECIMAL(14,2),
    supplier_share_of_council_pct  DECIMAL(9,6)
);

CREATE TABLE IF NOT EXISTS council.fact_spend (
    transaction_id                 VARCHAR(20)   PRIMARY KEY,
    transaction_date               DATE          NOT NULL,
    council_name                   VARCHAR(100)  NOT NULL,
    department                     VARCHAR(100)  NOT NULL,
    spend_category                 VARCHAR(100),
    supplier_name                  VARCHAR(150)  NOT NULL,
    description                    VARCHAR(255),
    actual_spend_gbp               DECIMAL(14,2) NOT NULL CHECK (actual_spend_gbp >= 0),
    budget_amount_gbp              DECIMAL(14,2) NOT NULL,
    spend_type                     VARCHAR(50),
    payment_status                 VARCHAR(30)   NOT NULL
        CHECK (payment_status IN ('Paid','Approved','Pending','Under Review','Cancelled')),
    procurement_method             VARCHAR(50),
    funding_source                 VARCHAR(100),
    currency                       CHAR(3)       NOT NULL CHECK (currency = 'GBP'),
    missing_supplier_flag          SMALLINT      NOT NULL CHECK (missing_supplier_flag IN (0,1)),
    is_recorded                    SMALLINT      NOT NULL CHECK (is_recorded IN (0,1)),
    variance_gbp                   DECIMAL(14,2),
    variance_pct                   DECIMAL(12,6),
    recorded_spend_gbp             DECIMAL(14,2),
    supplier_share_of_council_pct  DECIMAL(9,6)
);
