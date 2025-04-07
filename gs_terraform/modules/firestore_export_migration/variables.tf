variable "prefix" {
  description = "Prefix for the bucket name"
  type        = string
}

variable "firebase_gcs_bucket" {
  description = "The GCS bucket to store the Firestore export data"
  type        = string
}

variable "location" {
  description = "The location of the Firestore export data"

}

variable "project_id" {
  description = "The project id"
  type        = string

}