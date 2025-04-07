{{ config(
    materialized='table'
) }}


SELECT
    DATE(b.date_created) AS date_created,  -- The date from branch data
    SUM(b.installs) AS total_installs,     -- Sum of installs for the date
    ads.segments_date,                     -- Date from the ads data
    SUM(ads.metrics_cost_micros) / 1e6 AS total_ad_spend , -- Total ad spend (converted from micros)
     (SUM(ads.metrics_cost_micros) / 1e6) / SUM(b.installs) AS  cost_per_install
FROM `kasi-production.kasi_datainfra_ads_networks.ads_CampaignBasicStats_1279843096` AS ads
INNER JOIN `kasi-production.kasi_datainfra_branch_data.branch_data` AS b
    ON ads.segments_date = DATE(b.date_created)  -- Match dates between ads and branch data
GROUP BY DATE(b.date_created), ads.segments_date  -- Group by both dates to get daily totals
ORDER BY DATE(b.date_created), ads.segments_date
