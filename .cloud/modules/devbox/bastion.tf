resource "azurerm_public_ip" "devbox_bastion_pip" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = coalesce(var.bastion_pip_name, "${var.vm_name}-bastion-pip")
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "devbox_bastion" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = coalesce(var.bastion_name, "${var.vm_name}-bastion")
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = "Standard"

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.devbox_bastion_pip[0].id
  }

  lifecycle {
    precondition {
      condition     = var.bastion_subnet_id != null && var.bastion_subnet_id != ""
      error_message = "bastion_subnet_id must be set when enable_bastion_host is true."
    }
  }
}
