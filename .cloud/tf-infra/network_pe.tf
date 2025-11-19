# Private Endpoints 
# @see https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/key-vault-private-endpoint/

# https://learn.microsoft.com/en-us/azure/container-registry/container-registry-private-link
resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.acr_settings.private_link_enabled ? 1 : 0
  name                = "${var.acr_settings.name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main["PrivateEndpointSubnet"].id

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

# https://learn.microsoft.com/en-us/azure/key-vault/general/private-link-service?tabs=portal
resource "azurerm_private_endpoint" "kv_pe" {
  for_each = toset(var.environments)

  name                = "${var.project}-kv-${each.value}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.env[each.value].name
  subnet_id           = azurerm_subnet.main["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${var.project}-kv-${each.value}-pl"
    private_connection_resource_id = azurerm_key_vault.env[each.value].id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}
# https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-pl"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

