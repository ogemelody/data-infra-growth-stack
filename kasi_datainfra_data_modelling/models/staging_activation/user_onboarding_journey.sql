WITH first_open_data AS (
    SELECT
        user_id,
        distinct_id,
        time AS first_open_time
    FROM {{ source('mixpanel_existing_data', 'mp_master_event') }}
    WHERE event_name = '$ae_first_open'
),

account_issued_data AS (
    SELECT
        user_id
        distinct_id,
        time AS account_issued_time
    FROM {{ source('mixpanel_existing_data', 'mp_master_event') }}
    WHERE event_name = 'account_issued'
),

deposit_data AS (
    SELECT
        user_id,
        distinct_id,
        time AS deposit_time,
        JSON_EXTRACT_SCALAR(properties, '$.amount') AS deposit_amount,
        ROW_NUMBER() OVER (PARTITION BY distinct_id ORDER BY time ASC) AS deposit_rank
    FROM {{ source('mixpanel_existing_data', 'mp_master_event') }}
    WHERE event_name = 'account_deposit'
)

SELECT
    f.user_id,
    f.distinct_id,
    f.first_open_time,
    ai.account_issued_time,
    d.deposit_time,
    d.deposit_amount,

    -- Time differences (durations)
    TIMESTAMP_DIFF(d.deposit_time, f.first_open_time, SECOND) AS first_open_to_deposit_seconds,
    TIMESTAMP_DIFF(d.deposit_time, ai.account_issued_time, SECOND) AS account_issued_to_deposit_seconds,
    TIMESTAMP_DIFF(ai.account_issued_time, f.first_open_time, SECOND) AS first_open_to_account_issued_seconds

FROM first_open_data f

-- Left join to capture all first opens even if account is not issued yet
LEFT JOIN account_issued_data ai
    ON f.distinct_id = ai.distinct_id

-- Left join to capture first deposits
LEFT JOIN deposit_data d
    ON f.distinct_id = d.distinct_id
   AND d.deposit_rank = 1  -- Only first deposit matters

-- Optional filtering if you only care about users who have actually deposited
-- WHERE d.deposit_time IS NOT NULL

ORDER BY f.distinct_id
