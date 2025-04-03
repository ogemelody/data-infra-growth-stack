{{ config(
    materialized='table'
) }}

SELECT
    ca.linked_to_customer_id,
    ca.date_linked,
    ca.customer_id,
    ca.linked_to_customer_name,
    ca.status,
    ca.location_linked.lat,
    ca.location_linked.long,
    ci.billing_account_type

from `kasi-production.kasi_datainfra_firestore_export_from_gcs.cards` ca
LEFT JOIN `kasi-production.kasi_datainfra_all_tables.customers_info` AS ci
ON LOWER(ca.linked_to_customer_name) = LOWER(ci.full_name_source_customer_collection)