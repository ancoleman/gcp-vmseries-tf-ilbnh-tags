# --------------------------------------------------------------------------------------------------------------------------
# Create firewall VPCs & subnets

module "vpc_mgmt" {
  source               = "./modules/google_vpc/"
  vpc                  = "mgmt-vpc"
  delete_default_route = false
  allowed_sources      = var.mgmt_sources
  allowed_protocol     = "TCP"
  allowed_ports        = ["443", "22"]

  subnets = {
    "mgmt-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_mgmt[0]
    },
    "mgmt-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_mgmt[1]
    }
  }
}

module "vpc_untrust" {
  source               = "./modules/google_vpc/"
  vpc                  = "untrust-vpc"
  delete_default_route = false
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "untrust-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_untrust[0]
    },
    "untrust-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_untrust[1]
    }
  }
}

module "vpc_trust" {
  source               = "./modules/google_vpc/"
  vpc                  = "trust-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "trust-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_trust[0]
    },
    "trust-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_trust[1]
    }
  }
}

module "vpc_spoke1" {
  source               = "./modules/google_vpc/"
  vpc                  = "spoke1-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "spoke1-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_spoke1[0]
    },
    "spoke1-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_spoke1[1]
    }
  }
}

module "vpc_spoke2" {
  source               = "./modules/google_vpc/"
  vpc                  = "spoke2-vpc"
  delete_default_route = true
  allowed_sources      = ["0.0.0.0/0"]

  subnets = {
    "spoke2-${var.regions[0]}" = {
      region = var.regions[0],
      cidr   = var.cidrs_spoke2[0]
    },
    "spoke2-${var.regions[1]}" = {
      region = var.regions[1],
      cidr   = var.cidrs_spoke2[1]
    }
  }
}