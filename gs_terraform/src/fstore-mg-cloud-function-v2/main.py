import functions_framework
from google.cloud import bigquery
from datetime import datetime as dt
import os
import logging

# Collections of interest
COLLECTIONS_LIST = [
    "transactions", "uncleared_transactions", "waiting_list_stats", "notifications",
    "pargo_orders_customer_fan", "pargo_orders_webhook", "payouts", "pending_franc_transactions",
    "persona_verifications_created", "persona_verifications_expired",
    "persona_verifications_passed", "smile_identity_verifications", "stokvels",
    "iso_logoff_request", "iso_logon_request", "iso_notification_history",
    "iso_notification_request", "issued_cash_advance_logs", "kasi_company_analytics",
    "fraud_incident_reports", "fraud_watch_list", "flexpay_cardholder",
    "flexpay_notifications", "flexpay_payments", "customers", "configuration",
    "countries", "cards", "business", "business_manager", "banks", "app_reviews",
    "api_requests_reloadly", "agents"
]
logging.basicConfig(level=logging.INFO)
# Read environment variables
PROJECT_ID = os.getenv("PROJECT_ID")
BIGQUERY_DATASET = os.getenv("BIGQUERY_DATASET")

@functions_framework.cloud_event
def gcs_to_bigquery(cloud_event):
    try:
        data = cloud_event.data
        bucket_name = data["bucket"]
        file_name = data["name"]

        logging.info(f"file_name: {file_name}")
        logging.info("start process !!!")

        file_name_parts = file_name.split('/')
        collection_name = file_name_parts[-2].replace("kind_", "")
        
        if collection_name not in COLLECTIONS_LIST:
            return f"INFO ({dt.now().isoformat()}): The collection {collection_name} is not in the list of collections to be migrated"
        else:
            print("start process !!!")
            collection_name_kind = file_name_parts[-2]
            metadata_uri = f"gs://{bucket_name}/{'/'.join(file_name_parts[:-1])}/all_namespaces_{collection_name_kind}.export_metadata"
            table_id = f"{PROJECT_ID}.{BIGQUERY_DATASET}.{collection_name}"
            client = bigquery.Client(project=PROJECT_ID)
            job_config = bigquery.LoadJobConfig(
                source_format=bigquery.SourceFormat.DATASTORE_BACKUP,
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
                create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED,
            )

            load_job = client.load_table_from_uri(
                source_uris=metadata_uri,
                destination=table_id,
                job_config=job_config,
                project=PROJECT_ID
            )
            load_job.result()  # Wait for the job to complete
            
            return f"SUCCESS ({dt.now().isoformat()}): Table {collection_name} loaded to BigQuery."

    except KeyError as ke:
        return f"ERROR ({dt.now().isoformat()}): Missing key in cloud event data: {str(ke)}"
    
    except bigquery.exceptions.BadRequest as br:
        return f"ERROR ({dt.now().isoformat()}): BigQuery bad request: {str(br)}"
    except bigquery.exceptions.NotFound as nf:
        return f"ERROR ({dt.now().isoformat()}): BigQuery resource not found: {str(nf)}"
    except Exception as e:
        return f"ERROR ({dt.now().isoformat()}): Unexpected error occurred: {str(e)}"
