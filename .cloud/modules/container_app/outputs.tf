output "app_id" { value = azurerm_container_app.app.id }
output "app_name" { value = azurerm_container_app.app.name }
# For internal ingress, Azure still provides an FQDN that resolves privately in the VNet
output "app_fqdn" { value = try(azurerm_container_app.app.ingress[0].fqdn, null) }
output "principal_id" {
  value       = var.user_assigned_identity != null ? var.user_assigned_identity.principal_id : try(azurerm_container_app.app.identity[0].principal_id, null)
  description = "The Principal ID of the active identity (User Assigned if provided, else System Assigned)."
}
