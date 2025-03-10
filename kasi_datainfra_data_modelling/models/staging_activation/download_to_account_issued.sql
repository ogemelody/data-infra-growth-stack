--work on the duplicates present

WITH first_open_data AS (
    SELECT
        distinct_id,
        event_name,
        time AS first_open_time
    FROM `kasi-production.mixpanel_existing_data.mp_master_event`
    WHERE event_name = '$ae_first_open'
),
deposit_data AS (
    SELECT
        distinct_id,
        time AS deposit_time
    FROM `kasi-production.mixpanel_existing_data.mp_master_event`
)
SELECT
    f.distinct_id,
    f.first_open_time,
    d.deposit_time,
    TIMESTAMP_DIFF(d.deposit_time, f.first_open_time, SECOND) AS time_to_deposit_seconds
FROM first_open_data f
JOIN deposit_data d
    ON f.distinct_id = d.distinct_id
WHERE d.deposit_time > f.first_open_time
ORDER BY f.distinct_id
