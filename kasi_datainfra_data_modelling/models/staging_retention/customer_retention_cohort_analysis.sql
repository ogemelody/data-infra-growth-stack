{{ config(
    materialized='table'
) }}

WITH CustomerFirstPurchase AS (
  -- Identify each customer's first purchase month
  SELECT
    sender_id,
    DATE_TRUNC(CAST(MIN(date) AS DATE), MONTH) AS first_purchase_month
  FROM `kasi-production.kasi_datainfra_all_tables.transactions`
  GROUP BY sender_id
),

CohortAnalysis AS (
  SELECT
    cfp.first_purchase_month,
    DATE_TRUNC(CAST(t.date AS DATE), MONTH) AS transaction_month_date,
    DATE_DIFF(DATE_TRUNC(CAST(t.date AS DATE), MONTH), cfp.first_purchase_month, MONTH) AS months_since_first_purchase,
    COUNT(DISTINCT t.sender_id) AS retained_customers
  FROM `kasi-production.kasi_datainfra_all_tables.transactions` t
  JOIN CustomerFirstPurchase cfp
    ON t.sender_id = cfp.sender_id
  GROUP BY
    cfp.first_purchase_month,
    transaction_month_date,
    months_since_first_purchase
)

SELECT
  c.first_purchase_month AS cohort_date, -- Full date for sorting
  FORMAT_DATE('%Y-%m', first_purchase_month) AS cohort_year_month, -- Formatted YYYY-MM for readability
  MAX(CASE WHEN months_since_first_purchase = 0 THEN retained_customers END) AS month_0,
  MAX(CASE WHEN months_since_first_purchase = 1 THEN retained_customers END) AS month_1,
  MAX(CASE WHEN months_since_first_purchase = 2 THEN retained_customers END) AS month_2,
  MAX(CASE WHEN months_since_first_purchase = 3 THEN retained_customers END) AS month_3,
  MAX(CASE WHEN months_since_first_purchase = 4 THEN retained_customers END) AS month_4,
  MAX(CASE WHEN months_since_first_purchase = 5 THEN retained_customers END) AS month_5,
  MAX(CASE WHEN months_since_first_purchase = 6 THEN retained_customers END) AS month_6,
  MAX(CASE WHEN months_since_first_purchase = 7 THEN retained_customers END) AS month_7,
  MAX(CASE WHEN months_since_first_purchase = 8 THEN retained_customers END) AS month_8,
  MAX(CASE WHEN months_since_first_purchase = 9 THEN retained_customers END) AS month_9,
  MAX(CASE WHEN months_since_first_purchase = 10 THEN retained_customers END) AS month_10,
  MAX(CASE WHEN months_since_first_purchase = 11 THEN retained_customers END) AS month_11
FROM CohortAnalysis c
GROUP BY
  first_purchase_month, cohort_date, cohort_year_month
ORDER BY
  cohort_date -- Sorting by full date
