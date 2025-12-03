# Private DNS zone lives in the backbone RG
resource "azurerm_private_dns_zone" "sbx_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

