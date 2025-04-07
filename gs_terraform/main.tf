provider "google" {
  project = var.project_id
  region  = "us-central1"
  #   zone    = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }

  backend "gcs" {
    bucket = "kasi-production.appspot.com"
    prefix = "terraform-backend/state"
  }
}

# I:\My Drive\Growthstack\kasi-production-3f93947faa77.json

module "fstore_exp_migration" {
  source              = "./modules/firestore_export_migration"
  prefix              = var.prefix
  firebase_gcs_bucket = var.firebase_gcs_bucket
  location            = var.location
  project_id          = var.project_id
}