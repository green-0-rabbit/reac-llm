############################
# Network (NIC)
############################
resource "azurerm_network_interface" "nexus" {
  name                = coalesce(var.nic_name, "${var.vm_name}-nic")
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}
