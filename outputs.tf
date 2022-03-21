output "mgmt_vpc_name" {
  value = module.vpc_mgmt.vpc_name
}

output "mgmt_vpc_id" {
  value = module.vpc_mgmt.vpc_id
}

output "mgmt_vpc_self_link" {
  value = module.vpc_mgmt.vpc_self_link
}

output "mgmt_subnet_self_links" {
  value = module.vpc_mgmt.subnet_self_link
}

output "trust_vpc_name" {
  value = module.vpc_trust.vpc_name
}

output "trust_vpc_id" {
  value = module.vpc_trust.vpc_id
}

output "trust_vpc_self_link" {
  value = module.vpc_trust.vpc_self_link
}

output "trust_subnet_self_links" {
  value = module.vpc_trust.subnet_self_link
}

output "untrust_vpc_name" {
  value = module.vpc_untrust.vpc_name
}

output "untrust_vpc_id" {
  value = module.vpc_untrust.vpc_id
}

output "untrust_vpc_self_link" {
  value = module.vpc_untrust.vpc_self_link
}

output "untrust_subnet_self_links" {
  value = module.vpc_untrust.subnet_self_link
}

output "project_id" {
  value = var.project_id
}

output "bucket_name" {
  value = var.bucket_name
}

output "vm_user" {
  value = var.vm_user
}