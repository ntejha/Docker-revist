terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.17.0"
    }
  }
}

provider "google" {
  project     = "alert-ground-486213-p9"
  region      = "asia-south1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "alert-ground-486213-p9"
  location      = "ASIA-SOUTH1"
  force_destroy = true
  
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}