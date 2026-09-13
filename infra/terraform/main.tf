module "network" {
  source               = "./modules/network"
  resource_group_name  = var.resource_group_name
  location             = var.location
}

module "security" {
  source               = "./modules/security"
  location             = module.network.location
  resource_group_name  = module.network.resource_group_name
  admin_ip             = var.admin_ip
}

module "compute" {
  source               = "./modules/compute"
  resource_group_name  = module.network.resource_group_name
  location             = module.network.location
  subnet_id            = module.network.subnet_id
  nsg_id               = module.security.nsg_id
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  ssh_public_key_path  = var.ssh_public_key_path
  worker_count         = var.worker_count
}