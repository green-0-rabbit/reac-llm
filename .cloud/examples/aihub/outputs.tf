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
  # value       = null
  description = "Log Analytics Workspace ID."
}

output "frontend_aihub_fqdn" {
  value       = module.frontend_aihub.app_fqdn
  description = "FQDN of the Frontend Container App."
}

/*
output "backend_aihub_fqdn" {
  value       = module.backend_aihub.app_fqdn
  description = "FQDN of the Container App."
}

output "backend_aihub_name" {
  value       = module.backend_aihub.app_name
  description = "Name of the Container App."
}

output "container_app_environment_id" {
  value       = module.container_app_environment.id
  description = "ID of the Container App Environment."
}
*/

### AI foundry Outputs
output "ai_foundry_id" {
  value       = module.ai_foundry.ai_foundry_id
  description = "AI Foundry ID."
}
output "ai_foundry_name" {
  value       = module.ai_foundry.ai_foundry_name
  description = "AI Foundry Name."
}
output "cognitive_deployment_id" {
  value       = module.ai_foundry.cognitive_deployment_id
  description = "Cognitive Deployment ID."
}
output "private_endpoint_network_interface" {
  value       = module.ai_foundry.private_endpoint_network_interface
  description = "AI Foundry Private Endpoint Network Interface."
}

### Postgres Outputs
output "postgres_fqdn" {
  value       = module.postgres.fqdn
  description = "FQDN of the PostgreSQL Flexible Server."
}

output "postgres_server_name" {
  value       = module.postgres.server_name
  description = "Name of the PostgreSQL Flexible Server."
}

output "postgres_database_name" {
  value       = "aihub"
  description = "Name of the PostgreSQL database."
}

output "postgres_administrator_login" {
  value       = module.postgres.administrator_login
  description = "Administrator login for PostgreSQL."
}
