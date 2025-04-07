output "fstore_mig_sa_id" {
  value = google_service_account.firestore_export_migration_service_account.id
}

output "fstore_mig_sa_email" {
  value = google_service_account.firestore_export_migration_service_account.email
}

output "fstore_mig_cloud_function_url_v1" {
  value = google_cloudfunctions2_function.fstore_mig_cloud_function_v1.service_config[0].uri
}

