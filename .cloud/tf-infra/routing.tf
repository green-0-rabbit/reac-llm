resource "azurerm_route_table" "aca" {
  name                = "${var.project}-aca-udr"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  bgp_route_propagation_enabled = true

  route {
    name                   = "default-egress"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ip_address
  }

  tags = {
    project = var.project
    env     = "main"
  }
}

resource "azurerm_subnet_route_table_association" "aca" {
  subnet_id      = azurerm_subnet.main["ACASubnet"].id
  route_table_id = azurerm_route_table.aca.id
}
