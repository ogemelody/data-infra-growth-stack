SELECT
event_date,

event_name,
session_traffic_source_last_click.manual_campaign.source as manual_campaign,
session_traffic_source_last_click.cross_channel_campaign.source as cross_channel_campaign_source,
session_traffic_source_last_click.cross_channel_campaign.source_platform as cross_channel_campaign_source_platform,
session_traffic_source_last_click.cross_channel_campaign.primary_channel_group as cross_channel_campaign_channel_group,
session_traffic_source_last_click.google_ads_campaign.campaign_name as google_ads_campaign,
session_traffic_source_last_click.google_ads_campaign.ad_group_name as google_ads_campaign_ads_group,
session_traffic_source_last_click.google_ads_campaign.account_name as google_ads_campaign_account_name

FROM `kasi-production.analytics_414405073.events_*`
where event_name = "first_open"
LIMIT 1000