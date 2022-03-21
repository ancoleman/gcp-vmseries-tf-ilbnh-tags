terraform {
  required_providers {
    panos = {
      source = "paloaltonetworks/panos"
    }
  }
  backend "gcs" {
    bucket = var.bucket_name
    prefix = "terraform/state"
  }
}

provider "panos" {
  username = var.panorama_username
  password = var.panorama_password
  hostname = var.panorama_host
}

provider "google" {
  project = var.project_id
  region  = var.regions[0]
}