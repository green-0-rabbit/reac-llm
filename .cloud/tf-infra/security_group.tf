resource "azurerm_network_security_group" "aca" {
  name                = "${var.project}-aca-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    project = var.project
    env     = "main"
  }
}

resource "azurerm_subnet_network_security_group_association" "aca" {
  subnet_id                 = azurerm_subnet.main["ACASubnet"].id
  network_security_group_id = azurerm_network_security_group.aca.id
}

resource "azurerm_network_security_rule" "allow_http_https" {
  name                        = "Allow-HTTP-HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aca.name
}

resource "azurerm_network_security_rule" "allow_aca_ports" {
  name                        = "Allow-ACA-Ports"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["31080", "31443", "30000-32767"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aca.name
}

resource "azurerm_network_security_rule" "deny_internet_inbound" {
  name                        = "Deny-Internet-Inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aca.name
}

resource "azurerm_network_security_rule" "allow_trusted_sources" {
  count                       = length(var.trusted_source_prefixes) > 0 ? 1 : 0
  name                        = "Allow-Trusted-Sources"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.trusted_source_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aca.name
}
