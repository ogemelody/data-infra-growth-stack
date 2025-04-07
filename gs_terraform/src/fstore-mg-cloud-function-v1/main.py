
from google.cloud import firestore
from google.cloud import storage
import os
import json
from datetime import datetime
from googleapiclient.discovery import build
import functions_framework

# Custom JSON encoder to handle DatetimeWithNanoseconds
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

# Environment variables (set these in your Cloud Function configuration)
project_id = os.getenv("PROJECT_ID")
bucket_name = os.getenv("BUCKET_NAME")
firestore_database_name = os.getenv("FIRESTORE_DATABASE")

# Authenticate to Firestore
firestore_client = firestore.Client(
    project=project_id,
)

# Authenticate to GCS
storage_client = storage.Client(
    project=project_id,
)
bucket = storage_client.bucket(bucket_name)

@functions_framework.cloud_event
def export_firestore_to_gcs(cloud_event):
    """
    HTTP Cloud Function to export Firestore collections to GCS
    """
    # print("request :", request.to_json())
    try:
        # Authenticate to Firestore
        firestore_client
        print(f"{datetime.now()} - Firestore client authenticated successfully.")
    except Exception as e:
        print(f"{datetime.now()} - Error authenticating Firestore client: {e}")
        return f"Error authenticating Firestore client: {e}", 500

    # Fetch collections
    try:
        collections = firestore_client.collections()
        collections_list = [collection.id for collection in collections]
        print(f"{datetime.now()} - Collections: {collections_list}")
    except Exception as e:
        print(f"{datetime.now()} - Error fetching collections: {e}")
        return f"Error fetching collections: {e}", 500

    datetime_string = datetime.now().strftime("%Y-%m-%d")
    print(f"{datetime.now()} - Datetime string: {datetime_string}")

    def firestore_gcs():
        """
        Export the Firestore database to GCS
        """
        try:
            # Connect to the Firestore Admin API
            firestore_admin = build("firestore", "v1", )
            print(f"{datetime.now()} - Firestore admin connected.")
            
            # Get the Firestore database path
            firestore_database_path = f"projects/{project_id}/databases/{firestore_database_name}"
            
            # Create the request body
            request_body = {
                "outputUriPrefix": f"gs://{bucket_name}/{datetime_string}",
                "collectionIds": collections_list
            }

            # Export the Firestore database
            request = firestore_admin.projects().databases().exportDocuments(
                name=firestore_database_path,
                body=request_body
            )
            response = request.execute()
            print(f"{datetime.now()} - Response: {response}")
            print(f"{datetime.now()} - Firestore database exported to GCS {bucket_name}.")
        except Exception as e:
            print(f"{datetime.now()} - Error exporting Firestore database: {e}")
            raise

    # Check if the folder exists
    try:
        blobs = list(bucket.list_blobs(prefix=datetime_string))
        if len(blobs) > 0:
            print(f"{datetime.now()} - Folder '{datetime_string}' exists in the bucket.")
            # Delete the blobs
            for blob in blobs:
                blob.delete()
            print(f"{datetime.now()} - Blobs deleted.")
        else:
            print(f"{datetime.now()} - Folder '{datetime_string}' does not exist in the bucket.")
    except Exception as e:
        print(f"{datetime.now()} - Error checking or deleting blobs: {e}")
        return f"Error checking or deleting blobs: {e}", 500

    # Export Firestore collections to GCS
    try:
        firestore_gcs()
    except Exception as e:
        return f"Error exporting Firestore database: {e}", 500

    return f"Firestore database exported to GCS {bucket_name}.", 200