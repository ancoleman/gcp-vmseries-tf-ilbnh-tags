#resource "random_id" "student" {
#  byte_length = 4
#}

resource "panos_panorama_template" "this" {
  name = "TPL-B-${var.vm_user}"
}

resource "panos_panorama_template_stack" "this" {
  name        = "TPL-SK-${var.vm_user}"
  description = "Student Template Stack ${var.vm_user}"
  templates   = [panos_panorama_template.this.name]
}

resource "panos_device_group" "this" {
  name        = "DG-${var.vm_user}"
  description = "Student Device Group ${var.vm_user}"
}

resource "panos_device_group_parent" "gcp" {
  device_group = panos_device_group.this.name
  parent       = "GoogleCloud"
}

resource "panos_panorama_ethernet_interface" "eth1" {
  name                      = "ethernet1/1"
  template                  = panos_panorama_template.this.name
  mode                      = "layer3"
  enable_dhcp               = true
  create_dhcp_default_route = true
  dhcp_default_route_metric = 10
}

resource "panos_panorama_zone" "untrust" {
  name     = "untrust"
  template = panos_panorama_template.this.name
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.eth1.name
  ]
}

resource "panos_panorama_ethernet_interface" "eth2" {
  name                      = "ethernet1/2"
  template                  = panos_panorama_template.this.name
  mode                      = "layer3"
  enable_dhcp               = true
  create_dhcp_default_route = false
  dhcp_default_route_metric = 10
  management_profile        = panos_panorama_management_profile.healthcheck.name
}

resource "panos_panorama_zone" "trust" {
  name     = "trust"
  template = panos_panorama_template.this.name
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.eth2.name
  ]
}

resource "panos_panorama_static_route_ipv4" "hc1" {
  destination    = "35.191.0.0/16"
  name           = "hc1"
  next_hop       = panos_panorama_template_variable.next-hop-gw.name
  type           = "ip-address"
  interface      = "ethernet1/2"
  virtual_router = panos_panorama_virtual_router.example.name
  template       = panos_panorama_template.this.name
}

resource "panos_panorama_static_route_ipv4" "hc2" {
  destination    = "130.211.0.0/22"
  name           = "hc2"
  next_hop       = panos_panorama_template_variable.next-hop-gw.name
  type           = "ip-address"
  interface      = "ethernet1/2"
  virtual_router = panos_panorama_virtual_router.example.name
  template       = panos_panorama_template.this.name
}

resource "panos_panorama_static_route_ipv4" "spokes" {
  destination    = "10.0.0.0/8"
  name           = "spokes"
  next_hop       = panos_panorama_template_variable.next-hop-gw.name
  type           = "ip-address"
  interface      = "ethernet1/2"
  virtual_router = panos_panorama_virtual_router.example.name
  template       = panos_panorama_template.this.name
}

resource "panos_panorama_template_variable" "next-hop-ilb" {
  template = panos_panorama_template.this.name
  name     = "$nexthopilb"
  type     = "ip-netmask"
  value    = "10.1.1.1/24"
}

resource "panos_panorama_template_variable" "next-hop-gw" {
  template = panos_panorama_template.this.name
  name     = "$nexthopgw"
  type     = "ip-netmask"
  value    = "10.2.2.1/24"
}

resource "panos_panorama_virtual_router" "example" {
  template = panos_panorama_template.this.name
  name     = "vr-default"
  vsys     = "vsys1"
  interfaces = [
    panos_panorama_ethernet_interface.eth1.name,
    panos_panorama_ethernet_interface.eth2.name
  ]
}

resource "panos_panorama_management_profile" "healthcheck" {
  name          = "health-check-https"
  template      = panos_panorama_template.this.name
  permitted_ips = ["130.211.0.0/22", "35.191.0.0/16"]
  https         = true
}

#Break Egress

#resource "panos_panorama_nat_rule_group" "out-all" {
#  rule {
#    name = "out-all"
#    original_packet {
#      destination_addresses = ["any"]
#      destination_zone      = panos_panorama_zone.untrust.name
#      source_addresses      = ["any"]
#      source_zones          = [panos_panorama_zone.trust.name]
#    }
#    translated_packet {
#      destination {
#      }
#      source {
#        dynamic_ip_and_port {
#          interface_address {
#            interface = "ethernet1/1"
#          }
#        }
#      }
#    }
#  }
#}

resource "panos_panorama_service_object" "tcp220" {
    name = "tcp-220"
    protocol = "tcp"
    description = "us-east-1-nat SSH TCP 220"
    destination_port = "220"
}


resource "panos_panorama_nat_rule_group" "us-east-1-nat" {
  device_group       = panos_device_group.this.name
  rule {
    name = "us-east-1-nat"
    original_packet {
      destination_addresses = ["any"]
      destination_zone      = panos_panorama_zone.untrust.name
      source_addresses      = ["any"]
      source_zones          = [panos_panorama_zone.untrust.name]
      service               = panos_panorama_service_object.tcp220.name
    }
    translated_packet {
      destination {
        dynamic_translation {
          address      = "10.0.3.10"
          port         = "22"
          distribution = "round-robin"
        }
      }
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/2"
          }
        }
      }
    }
  }
}

resource "panos_panorama_service_object" "tcp221" {
    name = "tcp-221"
    protocol = "tcp"
    description = "us-west-1-nat SSH TCP 221"
    destination_port = "221"
}

resource "panos_panorama_nat_rule_group" "us-west-1-nat" {
  device_group       = panos_device_group.this.name
  rule {
    name = "us-west-1-nat"
    original_packet {
      destination_addresses = ["any"]
      destination_zone      = panos_panorama_zone.untrust.name
      source_addresses      = ["any"]
      source_zones          = [panos_panorama_zone.untrust.name]
      service               = panos_panorama_service_object.tcp221.name
    }
    translated_packet {
      destination {
        dynamic_translation {
          address      = "10.0.4.26"
          port         = "22"
          distribution = "round-robin"
        }
      }
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = "ethernet1/2"
          }
        }
      }
    }
  }
}

resource "panos_address_object" "gcp-health-check-1" {
    name = "gcp-health-check-1"
    value = "130.211.0.0/22"
    description = "GCP Load Balancer Source Range"
}

resource "panos_address_object" "gcp-health-check-2" {
    name = "gcp-health-check-2"
    value = "35.191.0.0/16"
    description = "GCP Load Balancer Source Range"
}

resource "panos_address_group" "gcp-health-check" {
    name = "gcp-healthchecks"
    description = "MGCP Load Balancer Source Ranges"
    static_addresses = [
        panos_address_object.gcp-health-check-1.name,
        panos_address_object.gcp-health-check-2.name,
    ]
}


resource "panos_panorama_security_rule_group" "this" {
  position_keyword   = "before"
  position_reference = panos_panorama_security_rule_group.deny.rule.0.name
  device_group       = panos_device_group.this.name
  rule {
    name                  = "gcp-health-checks"
    description           = "LB Healthchecks"
    source_zones          = [panos_panorama_zone.trust.name]
    source_addresses      = [panos_address_group.gcp-health-check.name]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["service-https"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
  rule {
    name                  = "student-gcp-trust-to-untrust"
    description           = "Temporary Permit Any on GWLB main interface"
    source_zones          = [panos_panorama_zone.trust.name]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = [panos_panorama_zone.untrust.name]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
  rule {
    name                  = "student-gcp-untrust-to-trust"
    description           = "Temporary Permit Any on GWLB main interface"
    source_zones          = [panos_panorama_zone.untrust.name]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = [panos_panorama_zone.trust.name]
    destination_addresses = ["any"]
    applications          = ["ssh", "web-browsing"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    log_setting           = "default"
  }
}

resource "panos_panorama_security_rule_group" "deny" {
  position_keyword = "bottom"
  device_group     = panos_device_group.this.name
  rule {
    name                  = "deny-all"
    description           = "Deny All"
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "deny"
    log_setting           = "default"
  }
}


output "lab_info" {
  value = {
    "Panorama URL"     = "https://${var.panorama_host}"
    "Student User"     = var.vm_user
    "Student Password" = var.vm_user
    "LNotes"           = "Login using these credentials to Panorama"
  }
}