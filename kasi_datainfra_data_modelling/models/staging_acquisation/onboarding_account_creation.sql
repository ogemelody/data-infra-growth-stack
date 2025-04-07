WITH source_data AS (
    SELECT
        user_id,
        time,
        event_name,
         --  extract 'profession' only for 'customer_profession' events
        CASE
            WHEN event_name = 'customer_profession' THEN
                JSON_EXTRACT_SCALAR(
                    REPLACE(TO_JSON_STRING(properties), '"profession"', '"_profession"'),
                    '$._profession'
                )
            ELSE NULL
        END AS profession,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"mp_country_code"', '"_mp_country_code"'),
            '$._mp_country_code'
        ) AS mp_country_code,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$region"', '"_region"'),
            '$._region'
        ) AS region,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$city"', '"_city"'),
            '$._city'
        ) AS city,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$app_version"', '"_app_version"'),
            '$._app_version'
        ) AS app_version,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$device_id"', '"_device_id"'),
            '$._device_id'
        ) AS device_id,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$brand"', '"_brand"'),
            '$._brand'
        ) AS brand,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$carrier"', '"_carrier"'),
            '$._carrier'
        ) AS carrier,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$has_telephone"', '"_has_telephone"'),
            '$._has_telephone'
        ) AS has_telephone,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$manufacturer"', '"_manufacturer"'),
            '$._manufacturer'
        ) AS manufacturer,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$model"', '"_model"'),
            '$._model'
        ) AS model,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$os"', '"_os"'),
            '$._os'
        ) AS os,
        JSON_EXTRACT_SCALAR(
            REPLACE(TO_JSON_STRING(properties), '"$os_version"', '"_os_version"'),
            '$._os_version'
        ) AS os_version,
        distinct_id


    FROM {{ source('mixpanel_existing_data', 'mp_master_event') }}
    WHERE event_name IN ('create_customer_complete', 'customer_profession','$ae_first_open')
)


SELECT * FROM source_data
