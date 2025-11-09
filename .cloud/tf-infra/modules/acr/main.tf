locals {
  # required for ACR Private Link @see https://learn.microsoft.com/en-us/azure/container-registry/container-registry-private-link#private-dns-zone  
  dns_zone_name = "privatelink.azurecr.io"

  private_link_vnet_links = {
    for idx, id in var.vnet_ids : format("%03d", idx) => id
  }
}

# ACR
resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}

# Private DNS zone for ACR Private Link
resource "azurerm_private_dns_zone" "acr" {
  count               = var.create_private_link_dns_zone ? 1 : 0
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the zone to provided VNets (if any)
resource "azurerm_private_dns_zone_virtual_network_link" "acr_links" {
  for_each = var.create_private_link_dns_zone ? local.private_link_vnet_links : {}

  name                  = "${var.dns_link_name_prefix}-${each.key}"
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = each.value
  registration_enabled  = false
  tags                  = var.tags
}
