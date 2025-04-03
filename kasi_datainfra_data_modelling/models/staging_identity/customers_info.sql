
{{ config(
    materialized='table'
) }}


WITH customers AS (
    SELECT
        bank_account.date_issued,
        created_at.date_time AS created_at_datetime,
        u_id,
        title,
        first_name,
        last_name,
        user_name,
        first_name || ' ' || last_name AS full_name_source_customer_collection,
        email,
        LOWER(gender) AS gender,
        date_of_birth.date_time AS date_of_birth_datetime,
        address.province,
        address.line_one,
        address.line_two,
        address.city,
        address.residential_status_code,
        address.suburb,
        address.postal_code,
        job_category,
        bank_account.account_number,
        bank_account.card_number,
        bank_account.card_status,
        bank_account.card_holder_id,
        account_status,
        account_type.type AS account_type,
        CASE
        WHEN billing.account_type = 'Professional' THEN 'Subscriber'
        ELSE billing.account_type
    END AS billing_account_type,
        billing.billing_update.previous_account_type AS billing_previous_account_type,
        billing.billing_update.updated_on AS billing_updated_on,
        account_status_updates.last_change,
        account_status_updates.latest_update_date,
        account_status_updates.updated_by,
        profile_image_skipped,
        app_version.version,
        app_version.platform,
        app_version.force_update,
        failed_submissions_data.country AS failed_submissions_data_by_country,
        failed_submissions_data.id_passport_number AS failed_submissions_data_id_passport_number,
        failed_submissions_data.passport_issue_date,
        failed_submissions_data.passport_expiry_date,
        failed_submissions_data.identity_type,
        electricity_meter_number,
        water_meter_number,
        referral_code_used,
        issued_account_viewed,
        user_name_viewed,
        fraud_risk.status_level,
        fraud_risk.incident_reports,
        fraud_risk.update_date,
        businesses[SAFE_OFFSET(0)].permissions AS business_permissions,
        businesses[SAFE_OFFSET(0)].business_id AS business_id,
        bank_account.confirmation_letter_generation_date,
        bank_account.available_balance.float AS bank_account_available_balance_float_value,
        bank_account.available_balance.integer AS bank_account_available_balance_integer_value,
        bank_account.available_balance.provided,
        bank_account.card_id,
        deep_link_campaign_id,
        deep_link_source,
        deep_link_campaign,
        deep_link_click_http_referrer,
        deep_link_referral_code,
        phone_number,
        phone_number_old,
        sms_phone_number,
        visa_document_base_64,
        declined_by,
        hide_order_card_from_home,
        smile_identity_verification.smile_identity_status,
        LOWER(os) AS os,
        approved_by,
        approved_by_id,
        cash_advance.status AS cash_advance_status,
        cash_advance.has_active_cash_advance,
        cash_advance.cash_advance_limit_cents,
        cash_advance.total_early_payments,
        cash_advance.monthly_missed_payments.d_2 AS cash_advance_monthly_missed_payments,
        cash_advance.monthly_cash_advance_count.d_2 AS cash_advance_monthly_cash_advance_count,
        declined_by_id,
        verification_decline_reason,
        permanently_hide_account_fee_display,
        subscription_payments.number_of_missed_subscription_payments,
        subscription_payments.missed_payment_date,
        identity.citizenship.country,
        identity.citizenship.code,
        identity.citizenship.id_passport_number AS identity_citizenship_id_passport_number,
        identity.citizenship.residence_indicator,
        identity.citizenship.passport_issue_date AS passport_issue_date_datetime,
        pargo_card_order.pickup_point.country AS pargo_card_order_country_pickup_point,
        pargo_card_order.pickup_point.city AS pargo_card_order_pickup_point_city,
        pargo_card_order.pickup_point.postalCode AS pargo_card_order_pickup_point_postal_code,
        pargo_card_order.pickup_point.address1 AS pargo_card_order_pickup_point_address1,
        pargo_card_order.pickup_point.address2 AS pargo_card_order_pickup_point_address2,
        pargo_card_order.tracking_code,
        referring_customer,
        passport_expiry_date_string,
        visa.visa_type,
        referral_code,
        onboarding_branch_deep_link.branch_username,
        onboarding_branch_deep_link.branch_feature,
        onboarding_branch_deep_link.branch_profession,
        onboarding_branch_deep_link.branch_channel,
        onboarding_branch_deep_link.branch_fica_indicator,
        onboarding_branch_deep_link.branch_account_status,
        onboarding_branch_deep_link.branch_id_type,
        onboarding_branch_deep_link.branch_citizenship,
        onboarding_branch_deep_link.branch_campaign,
        LOWER(onboarding_branch_deep_link.branch_gender) AS branch_deep_link_branch_gender
    FROM {{ source('kasi_datainfra_firestore_export_from_gcs', 'customers') }}
),

cards AS (
    SELECT
        linked_to_customer_name,
        linked_to_customer_id,
        date_linked,
        status AS status_from_cards
    FROM {{ source('kasi_datainfra_firestore_export_from_gcs', 'cards') }}
),

mixpanel_deduplicated AS (
    -- Deduplicate by keeping only one record per customer name
    SELECT
        customer_name_source_mixpanel,
        customer_id_source_mixpanel
    FROM (
        SELECT
            JSON_VALUE(properties, '$.customer_id') AS customer_id_source_mixpanel,
            JSON_VALUE(properties, '$.customer_name') AS customer_name_source_mixpanel,
            ROW_NUMBER() OVER (PARTITION BY JSON_VALUE(properties, '$.customer_name') ORDER BY time DESC) AS row_num
        FROM {{ source('mixpanel_existing_data', 'mp_master_event') }}
        WHERE event_name = 'account_deposit'
    )
    WHERE row_num = 1 -- Keeps only one entry per customer name
),

final_data AS (
    SELECT
        c.*,
        ca.linked_to_customer_id,
        ca.date_linked,
        ca.status_from_cards,
        m.customer_id_source_mixpanel,
        ROW_NUMBER() OVER (PARTITION BY c.full_name_source_customer_collection ORDER BY c.created_at_datetime DESC) AS row_num
    FROM customers c
    LEFT JOIN cards ca
        ON LOWER(c.full_name_source_customer_collection) = LOWER(ca.linked_to_customer_name)
    LEFT JOIN mixpanel_deduplicated m
        ON LOWER(COALESCE(c.full_name_source_customer_collection, ca.linked_to_customer_name)) = LOWER(m.customer_name_source_mixpanel)
)

SELECT
    COALESCE(final_data.linked_to_customer_id, final_data.customer_id_source_mixpanel) AS customer_id,
    final_data.*
FROM final_data
WHERE final_data.row_num = 1 -- Ensures only one row per full_name_source_customer_collection
