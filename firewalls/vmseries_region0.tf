# --------------------------------------------------------------------------------------------------------------------------
# Create bootstrap bucket for VM-Series, internal load balancer, and route to load balancer forwarding rule.

#module "bootstrap_region0" {
#  source        = "./modules/google_bootstrap/"
#  bucket_name   = "${local.prefix_region0}-bootstrap"
#  file_location = var.fw_region0_bootstrap_path
#  config        = ["init-cfg.txt", "bootstrap.xml"]
#  authcodes     = var.authcodes
#}

module "vmseries_region0" {
  source = "../modules/vmseries_unmanaged_ig/"
  image_name            = var.fw_image_name
  machine_type          = var.fw_machine_type
  create_instance_group = true
  project_id               = data.google_client_config.main.project

  metadata = {
    mgmt-interface-swap                  = "enable"
    serial-port-enable                   = true
    ssh-keys                             = fileexists(var.public_key_path) ? "admin:${file(var.public_key_path)}" : ""
    type                                 = "dhcp-client"
    plugin-op-commands                   = "panorama-licensing-mode-on"
    auth-key                             = var.sft_license_auth_key
    panorama-server                      = var.panorama_host
    dgname                               = var.dg_name
    tplname                              = var.tmpl_stck_name
    dhcp-send-hostname                   = "yes"
    dhcp-send-client-id                  = "yes"
    dhcp-accept-server-hostname          = "yes"
    dhcp-accept-server-domain            = "yes"
  }

  instances = {

    vmseries01 = {
      name             = "${local.prefix_region0}-vmseries01"
      zone             = data.google_compute_zones.region0.names[0]
#      bootstrap_bucket = module.bootstrap_region0.bucket_name
      network_interfaces = [
        {
          subnetwork = data.terraform_remote_state.gcsbucket.outputs.untrust_subnet_self_links["untrust-${var.regions[0]}"]
          public_nat = true
        },
        {
          subnetwork = data.terraform_remote_state.gcsbucket.outputs.mgmt_subnet_self_links["mgmt-${var.regions[0]}"]
          public_nat = true
        },
        {
          subnetwork = data.terraform_remote_state.gcsbucket.outputs.trust_subnet_self_links["trust-${var.regions[0]}"]
          public_nat = false
        }
      ]
    }
    # vmseries02 = {
    #   name             = "${local.prefix_region0}-vmseries02"
    #   zone             = data.google_compute_zones.region0.names[1]
    #   bootstrap_bucket = module.bootstrap_region0.bucket_name
    #   network_interfaces = [
    #     {
    #       subnetwork = module.vpc_untrust.subnet_self_link["untrust-${var.regions[0]}"]
    #       public_nat = true
    #     },
    #     {
    #       subnetwork = module.vpc_mgmt.subnet_self_link["mgmt-${var.regions[0]}"]
    #       public_nat = true
    #     },
    #     {
    #       subnetwork = module.vpc_trust.subnet_self_link["trust-${var.regions[0]}"]
    #       public_nat = false
    #     }
    #   ]
    # }
  }
}

resource "google_compute_region_backend_service" "region0" {
  name          = "${local.prefix_region0}-backend"
  region        = var.regions[0]
  health_checks = [google_compute_health_check.hc.id]
  network       = data.terraform_remote_state.gcsbucket.outputs.trust_vpc_id

  backend {
    group = module.vmseries_region0.instance_groups["vmseries01"]
  }
  # backend {
  #   group = module.vmseries_region0.instance_groups["vmseries02"]
  # }

}

resource "google_compute_forwarding_rule" "region0" {
  name   = "${local.prefix_region0}-forwarding-rule"
  region = var.regions[0]

  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.region0.id
  all_ports             = true
  network               = data.terraform_remote_state.gcsbucket.outputs.trust_vpc_id
  subnetwork            = data.terraform_remote_state.gcsbucket.outputs.trust_subnet_self_links["trust-${var.regions[0]}"]
  allow_global_access   = true
}

resource "google_compute_route" "region0" {
  name         = "${local.prefix_region0}-route"
  dest_range   = "0.0.0.0/0"
  network      = data.terraform_remote_state.gcsbucket.outputs.trust_vpc_id
  next_hop_ilb = google_compute_forwarding_rule.region0.id
  priority     = 1000
  tags         = ["${var.regions[0]}-fw"]
}

resource "google_compute_health_check" "hc" {
  name = "${local.prefix_region0}-hc"

  tcp_health_check {
    port = 443
  }
}