resource "azurerm_virtual_network" "main" {
  name                = "${var.project}-main-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.main_vnet_address_space
  tags = {
    project = var.project
    env     = "main"
  }
}

resource "azurerm_subnet" "main" {
  for_each             = var.main_vnet_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.address_prefix]
  dynamic "delegation" {
    for_each = try(each.value.delegation, null) != null ? [each.value.delegation] : []

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}
