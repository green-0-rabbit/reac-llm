# outputs
output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault ID for the environment."
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "Name of the infrastructure storage account."
}

### Container App Outputs

output "log_analytics_workspace_id" {
  value       = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : (length(azurerm_log_analytics_workspace.this) > 0 ? azurerm_log_analytics_workspace.this[0].id : null)
  description = "Log Analytics Workspace ID."
}

output "container_app_fqdn" {
  value       = module.container_app.app_fqdn
  description = "FQDN of the Container App."
}

output "container_app_name" {
  value       = module.container_app.app_name
  description = "Name of the Container App."
}

output "container_app_environment_id" {
  value       = module.container_app_environment.id
  description = "ID of the Container App Environment."
}

### Bastion Outputs

output "bastion_public_ip" {
  value = module.bastion_vm.vm_public_ip
}

output "bastion_private_ip" {
  value = module.bastion_vm.bastion_private_ip
}

