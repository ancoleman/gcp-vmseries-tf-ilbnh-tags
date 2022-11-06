# Permanent public address, not ephemeral.
resource "google_compute_address" "public" {
  region  = var.regions[1]
  name    = "panorama-public"
}

resource "google_compute_disk" "logging" {
  name = "panorama-logging-disk"
  zone = data.google_compute_zones.region1.names[0]
  type = "pd-ssd"
  size = 2000
}

resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.logging.id
  instance = google_compute_instance.panorama.id
}

resource "google_compute_instance" "panorama" {
  name                      = "lab-panorama"
  machine_type              = "n1-standard-16"
  zone                      = data.google_compute_zones.region1.names[0]
  can_ip_forward            = false
  allow_stopping_for_update = true

  metadata = {
    serial-port-enable = true
    ssh-keys           = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
  }

  network_interface {
    #    subnetwork = module.vpc_trust.subnet_self_link["trust-${var.regions[0]}"]
    subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.regions[1]}"]
    
    access_config {
        nat_ip = google_compute_address.public.address
      }
    }

  boot_disk {
    initialize_params {
      image = "projects/panw-gcp-team-testing/global/images/panorama-1023"
    }
  }
}
