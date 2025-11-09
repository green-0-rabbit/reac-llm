module "nexus_vm" {
  source = "./modules/nexus_vm"

  # Placement
  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location # e.g. "westeurope"
  subnet_id             = azurerm_subnet.main["WorkloadSubnet"].id
  bastion_subnet_prefix = azurerm_subnet.main["AzureBastionSubnet"].address_prefixes[0]

  # VM basics
  vm_name        = "vm-nexus-${var.env}"
  admin_username = var.admin_username
  admin_password = var.admin_password

  private_dns_zone_name = azurerm_private_dns_zone.sbx_zone.name # e.g. "sbx.example.com"
  private_dns_zone_rg   = azurerm_resource_group.main.name       # e.g. "sbx-main-rg" (zone holder RG)
  dns_record_name       = "nexus-${var.env}"                     # e.g. "nexus-dev"

  allowed_vnet_subnets = {
    ACASubnet = var.main_vnet_subnets["ACASubnet"].address_prefix
  }

}


