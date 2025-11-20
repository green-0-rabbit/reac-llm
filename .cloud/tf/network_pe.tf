# https://learn.microsoft.com/en-us/azure/key-vault/general/private-link-service?tabs=portal
resource "azurerm_private_endpoint" "kv_pe" {

  name                = "kv-${var.env}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "kv-${var.env}-pl"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.keyvault.id]
  }
}
# https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-pl"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage.id]
  }
}

