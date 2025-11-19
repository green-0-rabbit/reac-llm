# Reuse existing RG, VNet, and Subnets from your infra
# azurerm_resource_group.main, azurerm_virtual_network.main and azurerm_subnet.main[*] already exist.

module "acr" {
  source = "./modules/acr"

  acr_name            = var.acr_settings.name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.acr_settings.sku

  # DNS zone inside the module, linked to the main VNet for resolution
  create_private_link_dns_zone = true
  vnet_ids                     = [azurerm_virtual_network.main.id]
  dns_link_name_prefix         = "link-${var.project}-${var.env}"
}



