#!/bin/bash

# ✅ Ensure the .dbt directory exists
mkdir -p /root/.dbt

# ✅ Download profiles.yml from GCS
echo "Fetching dbt profiles.yml from GCS..."
gsutil cp gs://your-bucket-name/path/to/profiles.yml /root/.dbt/profiles.yml

# ✅ Run dbt
echo "Running dbt..."
dbt run

set -e
python3 main.py
