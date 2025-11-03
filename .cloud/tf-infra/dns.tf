# Private DNS zone lives in the backbone RG
resource "azurerm_private_dns_zone" "sbx_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

# Link it to the main VNet (so anything in that VNet resolves the zone privately)
resource "azurerm_private_dns_zone_virtual_network_link" "sbx" {
  name                  = "link-${azurerm_virtual_network.main.name}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sbx_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
