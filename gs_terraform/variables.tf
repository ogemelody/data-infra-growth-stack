variable "project_id" {
  description = "The GCP project to deploy resources to"

}

# variable "region" {
#   description = "The GCP region to deploy resources to"

# }

# variable "zone" {
#   description = "The GCP zone to deploy resources to"

# }

variable "prefix" {
  description = "A prefix to add to all resources"

}

variable "firebase_gcs_bucket" {
  description = "a bucket to store firebase export data"
}

variable "location" {
  description = "The location of the Firestore export data"

}