import requests

url = "https://api2.branch.io/v2/logs?app_id=1408526268688781696"

payload = {
    "report_type": "eo_install",
    "fields": ["name"],
    "limit": 100,
    "timezone": "America/Los_Angeles",
    "filter": ["eq", "name", "PURCHASE"],
    "response_format": "csv",
    "start_date": "2025-02-01T00:00:00Z",
    "end_date": "2025-02-23T00:00:00Z"
}
headers = {
    "accept": "application/json",
    "content-type": "application/json",
    "Access-Token": "api_app_9ebb0b1891fa4fa7830fa81cd1344ce9"
}

response = requests.post(url, json=payload, headers=headers)

print(response.text)