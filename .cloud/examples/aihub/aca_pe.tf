resource "azurerm_private_dns_zone" "aca" {
  name                = "privatelink.${var.location}.azurecontainerapps.io"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aca" {
  name                  = "aca-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.aca.name
  virtual_network_id    = module.vnet-spoke1.id
}

resource "azurerm_private_endpoint" "aca" {
  name                = "pe-${module.container_app_environment.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet-spoke1.subnet_ids["PrivateEndpointSubnet"]

  private_service_connection {
    name                           = "psc-${module.container_app_environment.name}"
    private_connection_resource_id = module.container_app_environment.id
    is_manual_connection           = false
    subresource_names              = ["managedEnvironments"]
  }

  private_dns_zone_group {
    name                 = "aca-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.aca.id]
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aca_hub" {
  name                  = "aca-link-hub"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.aca.name
  virtual_network_id    = data.azurerm_virtual_network.hub-vnet.id
}

