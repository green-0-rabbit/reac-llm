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

data "azurerm_key_vault_secret" "containerapp_cert" {
  name         = azurerm_key_vault_certificate.containerapp.name
  key_vault_id = azurerm_key_vault.this.id
}
