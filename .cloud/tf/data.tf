data "azurerm_subnet" "aca" {
  name                 = var.aca_subnet_name
  virtual_network_name = var.main_vnet_name
  resource_group_name  = var.main_rg_name
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.main_rg_name
}