resource "azurerm_bastion_host" "bastion" {
  name                = "${var.project}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = "Developer"

  virtual_network_id = var.vnet_id

}