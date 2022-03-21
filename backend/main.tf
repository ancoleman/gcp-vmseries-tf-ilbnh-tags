resource "google_storage_bucket" "this" {
  location      = "US"
  name          = var.bucket_name
  force_destroy = true
}