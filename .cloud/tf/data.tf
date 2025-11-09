data "azurerm_subnet" "workload" {
  name                 = var.workload_subnet_name # e.g. "snet-work"
  virtual_network_name = var.main_vnet_name       # e.g. "sbx-main-vnet"
  resource_group_name  = var.main_rg_name         # e.g. "sbx-main-rg" (backbone RG)
}

data "azurerm_subnet" "aca" {
  name                 = var.aca_subnet_name
  virtual_network_name = var.main_vnet_name
  resource_group_name  = var.main_rg_name
}

data "azurerm_subnet" "bastion" {
  name                 = var.bastion_subnet_name
  virtual_network_name = var.main_vnet_name
  resource_group_name  = var.main_rg_name
}