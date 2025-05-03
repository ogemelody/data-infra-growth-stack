import os
from google.cloud import storage
import subprocess

def download_from_gcs(bucket_name, prefix, local_dir):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blobs = bucket.list_blobs(prefix=prefix)

    for blob in blobs:
        if blob.name.endswith("/"):
            continue
        destination = os.path.join(local_dir, blob.name[len(prefix):])
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        blob.download_to_filename(destination)

def run():
    bucket_name = os.environ["GCS_BUCKET"]
    prefix = os.environ["DBT_PROJECT_PATH"]
    local_dir = "/app/dbt_project"

    download_from_gcs(bucket_name, prefix, local_dir)
    os.chdir(local_dir)

    subprocess.run(["dbt", "deps"])
    subprocess.run(["dbt", "run"])

if __name__ == "__main__":
    run()
