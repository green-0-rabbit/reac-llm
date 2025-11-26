output "id" {
  value       = azurerm_container_registry.this.id
  description = "ACR resource ID"
}

output "name" {
  value       = azurerm_container_registry.this.name
  description = "ACR name"
}

output "login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "ACR login server (e.g., <name>.azurecr.io)"
}

output "private_dns_zone_id" {
  value       = try(azurerm_private_dns_zone.acr[0].id, null)
  description = "ID of the privatelink.azurecr.io zone (if created)"
}

output "private_dns_zone_name" {
  value       = try(azurerm_private_dns_zone.acr[0].name, null)
  description = "Name of the privatelink.azurecr.io zone (if created)"
}
