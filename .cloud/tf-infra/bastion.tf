resource "azurerm_bastion_host" "bastion" {
  name                = "${var.project}-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Developer"

  virtual_network_id = azurerm_virtual_network.main.id
}