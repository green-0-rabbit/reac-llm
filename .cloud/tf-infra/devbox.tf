module "devbox_vm" {
  source = "../modules/devbox"

  project = var.project
  vm_size = "Standard_B2s"

  # Placement
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.vnet-hub.subnet_ids["MainSubnet"]

  # VM basics
  vm_name        = "vm-devbox-${var.env}"
  admin_username = var.admin_username
  admin_password = var.admin_password
  custom_image_id = var.devbox_custom_image_id

  # Identity
  enable_managed_identity = true

  # Bastion (dedicated)
  enable_bastion_host = true
  bastion_subnet_id   = module.vnet-hub.subnet_ids["AzureBastionSubnet"]

  # Dummy env vars for testing
  env_vars = {
    EXAMPLE_ONE = "value_one"
    EXAMPLE_TWO = "value_two"
  }
}
