module "bastion_vm" {
  source = "../../modules/bastion"

  project = var.project
  vm_size = "Standard_B2s_v2"

  # Placement
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  vnet_id             = module.vnet-spoke1.id
  subnet_id           = module.vnet-spoke1.subnet_ids["BastionSubnet"]

  # VM basics
  vm_name          = "vm-bastion-${var.env}"
  admin_username   = var.admin_username
  admin_password   = var.admin_password
  enable_public_ip = true

  # ACR / identity wiring
  enable_managed_identity = true
  acr_id                  = data.azurerm_container_registry.acr.id
  acr_name                = data.azurerm_container_registry.acr.name

  # IWM lab ACR
  remote_acr_config   = var.remote_acr_config
  remote_acr_password = var.remote_acr_password
}
