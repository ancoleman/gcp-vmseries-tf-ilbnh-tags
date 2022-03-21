data "terraform_remote_state" "gcsbucket" {
  backend = "gcs"
  config = {
    bucket = var.bucket_name
    prefix = "terraform/state"
  }
}