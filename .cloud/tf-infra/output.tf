output "private_dns_zone_name" {
  value       = azurerm_private_dns_zone.sbx_zone.name
  description = "Backbone private zone (e.g. sbx.example.com)."
}

output "private_dns_zone_rg" {
  value       = azurerm_resource_group.main.name
  description = "RG hosting the private DNS zone."
}

output "bastion_name" {
  value = azurerm_bastion_host.bastion.name
}

output "bastion_pip" {
  value = azurerm_public_ip.bastion.ip_address
}