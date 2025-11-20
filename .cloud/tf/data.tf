data "azurerm_subnet" "aca" {
  name                 = var.aca_subnet_name
  virtual_network_name = var.main_vnet_name
  resource_group_name  = var.main_rg_name
}

data "azurerm_subnet" "private_endpoint" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.main_vnet_name
  resource_group_name  = var.main_rg_name
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "sbx" {
  name                = var.private_dns_zone_name
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "keyvault" {
  name                = var.private_dns_zone_kv_name
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "storage" {
  name                = var.private_dns_zone_storage_name
  resource_group_name = var.main_rg_name
}
