# --------------------------------------------------------------------------------------------------------------------------
# Setup Terraform providers, pull the regions availability zones, and create naming prefix as local variable



data "google_compute_zones" "region0" {
  region = var.regions[0]
}

data "google_client_config" "main" {
}

data "google_compute_zones" "region1" {
  region = var.regions[1]
}

data "google_compute_zones" "region2" {
  region = var.regions[2]
}

locals {
    prefix_region0 = "${var.regions[0]}"
    prefix_region1 = "${var.regions[1]}"
    prefix_region2 = "${var.regions[2]}"
}