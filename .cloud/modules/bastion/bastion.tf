resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = "${var.project}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = "Standard"

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_host_pip[0].id
  }
}

resource "azurerm_public_ip" "bastion_host_pip" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = "${var.project}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}