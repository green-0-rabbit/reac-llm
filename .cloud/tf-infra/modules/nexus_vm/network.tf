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

resource "azurerm_network_interface_security_group_association" "nexus" {
  network_interface_id      = azurerm_network_interface.nexus.id
  network_security_group_id = azurerm_network_security_group.nexus.id
}


resource "azurerm_network_security_group" "nexus" {
  name                = coalesce(var.nsg_name, "${var.vm_name}-nsg")
  location            = var.location
  resource_group_name = var.resource_group_name
}


############################
# NSG Rules (for Nexus)
############################

# Allow Nexus UI (8081) from Bastion/admin CIDRs
resource "azurerm_network_security_rule" "ui_from_admin" {
  for_each                    = var.allowed_vnet_subnets
  name                        = "ui-from-${each.key}"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8081"
  source_address_prefix       = each.value
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nexus.name
}

# Allow HTTPS (443) from ACA subnets or other allowed CIDRs
resource "azurerm_network_security_rule" "https_from_allowed" {
  for_each                    = var.allowed_vnet_subnets
  name                        = "https-from-${each.key}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = each.value
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nexus.name
}

# Allow SSH from Azure Bastion
resource "azurerm_network_security_rule" "ssh_from_bastion" {
  name                        = "ssh-from-azurebastion"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.bastion_subnet_prefix
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nexus.name
}
