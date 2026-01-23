module "bastion_vm" {
  source = "../modules/bastion"

  project = var.project
  vm_size = "Standard_B1s"

  # Placement
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_id             = module.vnet-hub.id
  subnet_id           = module.vnet-hub.subnet_ids["BastionSubnet"]

  # VM basics
  vm_name             = "vm-bastion-${var.env}"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  enable_public_ip    = true
  enable_bastion_host = false

  # ACR / identity wiring
  enable_managed_identity = true
  acr_id                  = module.acr.id
  acr_name                = module.acr.name

  # IWM lab ACR
  remote_acr_config   = var.remote_acr_config
  remote_acr_password = var.remote_acr_password
}
