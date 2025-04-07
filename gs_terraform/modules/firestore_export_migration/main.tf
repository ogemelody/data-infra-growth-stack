# Service Account for Firestore Export Migration
resource "google_service_account" "firestore_export_migration_service_account" {
  account_id   = "${var.prefix}-fstore-mig-sa"
  display_name = "Firestore Export Migration Service Account"
}

# Custom Role for Firestore Export Migration
resource "google_project_iam_custom_role" "firestore_export_migration_role" {
  depends_on  = [google_service_account.firestore_export_migration_service_account]
  role_id     = "firestoreExportMigrationRole"
  title       = "${var.prefix}-fstore-mig-role"
  description = "Role for Firestore Export Migration Service Account"
  permissions = [
    "storage.buckets.get",
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    "cloudfunctions.functions.call",
    "pubsub.snapshots.seek",
    "pubsub.subscriptions.consume",
    "pubsub.topics.attachSubscription",
    "pubsub.topics.publish",
    "bigquery.datasets.create",
    "bigquery.tables.create",
    "bigquery.tables.delete",
    "bigquery.tables.updateData",
    "bigquery.tables.list",
    "bigquery.tables.update",
    "run.jobs.run",
    "run.routes.invoke",
    "datastore.entities.create",
    "datastore.entities.list",
    "datastore.entities.get",
    "eventarc.events.receiveEvent",
    "eventarc.events.receiveAuditLogWritten"
  ]
}

# IAM Bindings for Firestore Export Migration Service Account
resource "google_project_iam_binding" "fstore_mig_iam_bindings" {
  depends_on = [
    google_service_account.firestore_export_migration_service_account,
    google_project_iam_custom_role.firestore_export_migration_role
  ]
  
  project = var.project_id
  role    = google_project_iam_custom_role.firestore_export_migration_role.name
  members = [
    "serviceAccount:${google_service_account.firestore_export_migration_service_account.email}"
  ]
}

# IAM Member Bindings for specific roles
resource "google_project_iam_member" "fstore_mig_iam_member_bindings" {
  for_each = toset([
    "roles/eventarc.eventReceiver",
    "roles/datastore.owner",
    "roles/cloudfunctions.invoker",
    "roles/pubsub.publisher",
    "roles/logging.logWriter",
    "roles/run.invoker",
   "roles/bigquery.admin",
   "roles/logging.viewer"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.firestore_export_migration_service_account.email}"
}

# Custom Role for Firestore Export Migration Bucket Access
resource "google_project_iam_custom_role" "firestore_export_migration_bucket_role" {
  depends_on  = [google_service_account.firestore_export_migration_service_account]
  role_id     = "firestoreExportMigrationBucketRole"
  title       = "${var.prefix}-fstore-mig-bucket-role"
  description = "Role for Firestore Export Migration Bucket"
  permissions = [
    "storage.buckets.get",
    "storage.buckets.create",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "eventarc.events.receiveEvent",
    "pubsub.topics.publish",
    "run.jobs.run",
    "run.routes.invoke"
  ]
}

# Bucket Policy for Firestore Export Migration (Multiple Buckets)
resource "google_storage_bucket_iam_member" "fstore_mig_bucket_policy" {
  depends_on = [google_project_iam_custom_role.firestore_export_migration_bucket_role]
  for_each   = toset([
    "kasi-production.appspot.com",
    "kasi-datainfra-fstore-backup"
  ])
  bucket     = each.value
  role       = google_project_iam_custom_role.firestore_export_migration_bucket_role.name
  member     = "serviceAccount:${google_service_account.firestore_export_migration_service_account.email}"
}

# Pub/Sub Topic for Firestore Export Migration
resource "google_pubsub_topic" "fstore_mig_pubsub_topic" {
  name = "${var.prefix}-fstore-mig-topic"
}

# Cloud Scheduler Job for Firestore Export Migration (Pub/Sub trigger)
resource "google_cloud_scheduler_job" "fstore_mig_scheduler" {
  depends_on = [google_pubsub_topic.fstore_mig_pubsub_topic]
  name       = "${var.prefix}-fstore-mig-scheduler"
  schedule   = "0 0 * * *"

  pubsub_target {
    topic_name = google_pubsub_topic.fstore_mig_pubsub_topic.id
    data       = base64encode("test")
  }
}

# Cloud Function Archive (for both V1 and V2)
data "archive_file" "fstore_mig_cloud_function" {
  for_each   = toset( [
    "fstore-mg-cloud-function-v1",
    "fstore-mg-cloud-function-v2"
  ])
  type       = "zip"
  source_dir = "./src/${each.value}/"
  output_path = "./src/${each.value}.zip"
}

# Cloud Bucket for Storing Code
resource "google_storage_bucket_object" "fstore_mig_bucket_object" {
  for_each = data.archive_file.fstore_mig_cloud_function
  bucket   = var.firebase_gcs_bucket
  source   = each.value.output_path
  name     = each.key
}

# Cloud Function for Firestore Export Migration V1
resource "google_cloudfunctions2_function" "fstore_mig_cloud_function_v1" {

  
  name        = "${var.prefix}-fstore-mig-cloud-function-v1"
  description = "Firestore Export Migration Cloud Function V1 (Scheduled event)"
  location    = var.location

  build_config {
    runtime     = "python312"
    entry_point = "export_firestore_to_gcs"
    environment_variables = {
      PROJECT_ID         = var.project_id
      BUCKET_NAME        = google_storage_bucket.fstore_bucket.name
      FIRESTORE_DATABASE = "(default)"
    }
    source {
      storage_source {
        bucket = var.firebase_gcs_bucket
        object = google_storage_bucket_object.fstore_mig_bucket_object["fstore-mg-cloud-function-v1"].name
      }
    }
  }

  service_config {
    min_instance_count             = 1
    available_memory               = "512M"
    timeout_seconds                = 1800
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.firestore_export_migration_service_account.email
  }

  event_trigger {
    trigger_region = var.location
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.fstore_mig_pubsub_topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

# Cloud Function for Firestore Export Migration V2
resource "google_cloudfunctions2_function" "fstore_mig_cloud_function_v2" {
  depends_on = [ google_project_iam_member.fstore_mig_iam_member_bindings]

  name        = "${var.prefix}-fstore-mig-cloud-function-v2"
  description = "Firestore Export Migration Cloud Function V2 (Event Tracking)"
  location    = var.location

  build_config {
    runtime     = "python312"
    entry_point = "gcs_to_bigquery"

    source {
      storage_source {
        bucket = var.firebase_gcs_bucket
        object = google_storage_bucket_object.fstore_mig_bucket_object["fstore-mg-cloud-function-v2"].name
      }
    }
  }

  service_config {
    min_instance_count             = 0
    available_memory               = "512M"
    timeout_seconds                = 540
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.firestore_export_migration_service_account.email
    environment_variables = {
      PROJECT_ID         = var.project_id
      BIGQUERY_DATASET = "kasi_datainfra_firestore_export_from_gcs"
    }

  }

  event_trigger {
    event_type            = "google.cloud.storage.object.v1.finalized"
    trigger_region        = var.location
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.firestore_export_migration_service_account.email
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.fstore_bucket.name
    }
  }
}

# Cloud Storage Bucket for Firestore Export Migration
resource "google_storage_bucket" "fstore_bucket" {
  name          = "${var.prefix}-fstore-backup"
  location      = var.location
  project       = var.project_id
  force_destroy = true
  uniform_bucket_level_access = true
}

data "google_storage_project_service_account" "project" {
}

# To use GCS CloudEvent triggers, the GCS service account requires the Pub/Sub Publisher(roles/pubsub.publisher) IAM role in the specified project.
# (See https://cloud.google.com/eventarc/docs/run/quickstart-storage#before-you-begin)
resource "google_project_iam_member" "gcs-pubsub-publishing" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.project.email_address}"
}