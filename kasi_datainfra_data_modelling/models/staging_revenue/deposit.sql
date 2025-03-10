SELECT
  event_name,
  time,
  distinct_id,
  JSON_VALUE(properties, '$.amount') AS amount,
  JSON_VALUE(properties, '$.customer_id') AS customer_id,
  JSON_VALUE(properties, '$.customer_name') AS customer_name,
  JSON_VALUE(properties, '$.deposit_type') AS deposit_type
 FROM kasi-production.mixpanel_existing_data.mp_master_event
where event_name = 'account_deposit'
