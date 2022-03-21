#resource "random_id" "student" {
#  byte_length = 4
#}

resource "panos_panorama_template" "this" {
  name = "TPL-BASE-${var.vm_user}"
}

resource "panos_panorama_template_stack" "this" {
  name        = "TPL-STACK-${var.vm_user}"
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
  create_dhcp_default_route = true
  dhcp_default_route_metric = 10
}

resource "panos_panorama_zone" "trust" {
  name     = "trust"
  template = panos_panorama_template.this.name
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.eth2.name
  ]
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


resource "panos_panorama_security_rule_group" "this" {
  position_keyword = "bottom"
  device_group     = panos_device_group.this.name
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
}


#resource "null_resource" "panorama-python" {
#  depends_on = [panos_panorama_template_stack.this, panos_device_group.this]
#
#  provisioner "local-exec" {
#    when        = create
#    command     = "panorama.py"
#    interpreter = ["python3"]
#    environment = {
#      panorama_host       = var.panorama_host
#      panorama_username       = var.panorama_username
#      panorama_password   = var.panorama_password
#      panorama_student_id = random_id.student.id
#      panorama_destroy    = "False"
#    }
#  }
#}

output "lab_info" {
  value = {
    "Panorama URL"     = "https://${var.panorama_host}"
    "Student User"     = var.vm_user
    "Student Password" = var.vm_user
    "LNotes"           = "Login using these credentials to Panorama"
  }
}