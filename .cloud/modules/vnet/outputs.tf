output "id" {
  description = "The id of the newly created vNet"
  value       = azurerm_virtual_network.vnet.id
}

output "name" {
  description = "The Name of the newly created vNet"
  value       = azurerm_virtual_network.vnet.name
}

output "location" {
  description = "The location of the newly created vNet"
  value       = azurerm_virtual_network.vnet.location
}

output "address_space" {
  description = "The address space of the newly created vNet"
  value       = azurerm_virtual_network.vnet.address_space
}

output "subnet_ids" {
  description = "The ids of subnets created inside the newly created vNet"
  value       = { for s in azurerm_subnet.snet : s.name => s.id }
}

output "subnet_prefixes" {
  description = "The address prefixes of subnets created inside the newly created vNet"
  value       = { for s in azurerm_subnet.snet : s.name => s.address_prefixes[0] }
}

output "vnet_subnets_name_id" {
  description = "Can be used to output map of subnet names and their IDs"
  value       = { for key, val in azurerm_subnet.snet : key => val.id }
}

output "firewall_private_ip" {
  description = "The private IP of the Azure Firewall"
  value       = var.firewall != null ? azurerm_firewall.fw[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  description = "The public IP of the Azure Firewall"
  value       = var.firewall != null ? azurerm_public_ip.fw-pip[0].ip_address : null
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = var.firewall != null ? azurerm_firewall.fw[0].name : null
}

output "route_table_id" {
  description = "The ID of the route table"
  value       = (var.firewall != null || var.firewall_private_ip_address != null) ? azurerm_route_table.rt_to_firewall[0].id : null
}

