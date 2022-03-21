# --------------------------------------------------------------------------------------------------------------------------
# Setup Terraform providers, pull the regions availability zones, and create naming prefix as local variable

terraform {
  required_providers {
    panos = {
      source = "paloaltonetworks/panos"
    }
  }
}

provider "panos" {
  username = var.panorama_username
  password = var.panorama_password
  hostname = var.panorama_host
}

provider "google" {
  #credentials = var.auth_file
  project     = var.project_id
  region      = var.regions[0]
}

data "google_compute_zones" "region0" {
  region = var.regions[0]
}

data "google_client_config" "main" {
}

data "google_compute_zones" "region1" {
  region = var.regions[1]
}

locals {
    prefix_region0 = "${var.regions[0]}"
    prefix_region1 = "${var.regions[1]}"
}