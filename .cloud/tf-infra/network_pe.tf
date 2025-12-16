# Private Endpoints 
# @see https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview?
# @see https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/key-vault-private-endpoint/

# https://learn.microsoft.com/en-us/azure/container-registry/container-registry-private-link
resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.acr_settings.private_link_enabled ? 1 : 0
  name                = "${var.acr_settings.name}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.vnet-hub.subnet_ids["PrivateEndpointSubnet"]

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

