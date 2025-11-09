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


resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.acr_settings.private_link_enabled ? 1 : 0
  name                = "${var.acr_settings.name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main["WorkloadSubnet"].id

  private_service_connection {
    name                           = "${var.acr_settings.name}-pl"
    private_connection_resource_id = module.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  # Associate the PE with the DNS zone created by the module.
  private_dns_zone_group {
    name                 = "acr-plz-group"
    private_dns_zone_ids = compact([module.acr.private_dns_zone_id])
  }
}


