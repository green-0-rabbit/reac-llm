data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "acr" {
  name                = var.private_dns_zone_acr_name
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

data "azurerm_virtual_network" "hub-vnet" {
  name                = "${var.hub_vnet_name}-${var.location}"
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "postgres" {
  name                = var.private_dns_zone_postgres_name
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "monitor" {
  for_each            = toset(var.private_dns_azure_monitor_names)
  name                = each.value
  resource_group_name = var.main_rg_name
}

data "azurerm_private_dns_zone" "ai_services" {
  for_each            = toset(var.private_dns_azure_ai_names)
  name                = each.value
  resource_group_name = var.main_rg_name
}
