data "google_compute_zones" "region0" {
  region = var.regions[0]
}

data "google_client_config" "main" {
}

data "google_compute_zones" "region1" {
  region = var.regions[1]
}