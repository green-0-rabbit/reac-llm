# https://learn.microsoft.com/en-us/azure/key-vault/general/private-link-service?tabs=portal
resource "azurerm_private_endpoint" "kv_pe" {

  name                = "kv-${var.env}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.vnet-spoke1.subnet_ids["PrivateEndpointSubnet"]

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
  subnet_id           = module.vnet-spoke1.subnet_ids["PrivateEndpointSubnet"]

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

# https://learn.microsoft.com/en-us/azure/azure-monitor/logs/private-link-configure
resource "azurerm_private_endpoint" "ampls" {
  name                = "${azurerm_log_analytics_workspace.this[0].name}-pe-ampls"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet-spoke1.subnet_ids["PrivateEndpointSubnet"]

  private_service_connection {
    name                           = "${var.resource_group_name}-psc-ampls"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    is_manual_connection           = false

    # Group ID for Microsoft.Insights/privateLinkScopes
    subresource_names = ["azuremonitor"]
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = concat(
      values(data.azurerm_private_dns_zone.monitor)[*].id,
      [data.azurerm_private_dns_zone.storage.id]
    )
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.law_link
  ]
}



