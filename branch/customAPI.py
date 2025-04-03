import requests

# Replace with your actual Branch API Key
api_key = "YOUR_API_KEY"
url = "https://api.branch.io/v1/link/clicks"

# Set up the headers for authentication
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {api_key}"
}

params = {
    "link_id": "YOUR_LINK_ID",
    "date_start": "2023-01-01",
    "date_end": "2023-12-31"
}

# Make the API request
response = requests.get(url, headers=headers, params=params)

# Check if the request was successful
if response.status_code == 200:
    data = response.json()
    print(data)  # Process the data as needed
else:
    print(f"Failed to fetch data: {response.status_code}")
