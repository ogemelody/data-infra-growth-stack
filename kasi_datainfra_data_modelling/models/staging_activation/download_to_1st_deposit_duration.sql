{{ config(
    materialized='table'
) }}

WITH ranked_transactions AS (
    SELECT
        sender_id,
        date AS date_of_first_deposit,
        sender_name,
        sender_amount,
        debit,
        credit,
        transaction_type,
        ROW_NUMBER() OVER (PARTITION BY sender_id ORDER BY date ASC) AS row_num
    FROM `kasi-production.growth_stack_metrics_kasi_datainfra.transactions`
),

first_transactions AS (
    SELECT
        sender_id,
        date_of_first_deposit,
        sender_name,
        sender_amount,
        debit,
        credit,
        transaction_type
    FROM ranked_transactions
    WHERE row_num = 1
),

time_differences AS (
    SELECT
        ci.created_at_datetime,
        ft.date_of_first_deposit,
        DATE(ft.date_of_first_deposit) AS transaction_date,
        FORMAT_DATE('%Y-%m-%d', DATE_TRUNC(ft.date_of_first_deposit, WEEK))
            || ' to ' ||
        FORMAT_DATE('%Y-%m-%d', DATE_ADD(DATE_TRUNC(ft.date_of_first_deposit, WEEK), INTERVAL 6 DAY))
        AS transaction_week_range, -- Weekly Start & End Dates
        DATE_TRUNC(ft.date_of_first_deposit, MONTH) AS transaction_month,
        TIMESTAMP_DIFF(ft.date_of_first_deposit, ci.created_at_datetime, SECOND) AS download_to_deposit_seconds
    FROM first_transactions ft
    JOIN `kasi-production.growth_stack_metrics_kasi_datainfra.customers_info` ci
        ON ft.sender_id = ci.customer_id
)

SELECT
    period,
    period_value,
    avg_seconds
FROM (
    SELECT
        'Daily' AS period,
        CAST(transaction_date AS STRING) AS period_value,
        AVG(download_to_deposit_seconds) AS avg_seconds
    FROM time_differences
    GROUP BY transaction_date

    UNION ALL

    SELECT
        'Weekly' AS period,
        transaction_week_range AS period_value,
        AVG(download_to_deposit_seconds) AS avg_seconds
    FROM time_differences
    GROUP BY transaction_week_range

    UNION ALL

    SELECT
        'Monthly' AS period,
        CAST(transaction_month AS STRING) AS period_value,
        AVG(download_to_deposit_seconds) AS avg_seconds
    FROM time_differences
    GROUP BY transaction_month

    UNION ALL

    SELECT
        'All-Time' AS period,
        'All-Time' AS period_value,
        AVG(download_to_deposit_seconds) AS avg_seconds
    FROM time_differences
) final
