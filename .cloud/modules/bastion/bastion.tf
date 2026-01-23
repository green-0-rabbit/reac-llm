resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = "${var.project}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = "Developer"

  virtual_network_id = var.vnet_id

}