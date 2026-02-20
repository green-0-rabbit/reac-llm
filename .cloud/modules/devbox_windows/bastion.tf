resource "azurerm_bastion_host" "devbox_bastion" {
  count               = var.enable_bastion_host ? 1 : 0
  name                = coalesce(var.bastion_name, "${var.vm_name}-bastion")
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                = "Developer"
  virtual_network_id = var.virtual_network_id

  lifecycle {
    precondition {
      condition     = var.virtual_network_id != null && var.virtual_network_id != ""
      error_message = "virtual_network_id must be set when bastion_sku is Developer."
    }
  }
}
