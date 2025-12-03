# Handy outputs
output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault ID for the environment."
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "Name of the infrastructure storage account."
}

output "log_analytics_workspace_id" {
  value       = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : (length(azurerm_log_analytics_workspace.this) > 0 ? azurerm_log_analytics_workspace.this[0].id : null)
  description = "Log Analytics Workspace ID."
}
