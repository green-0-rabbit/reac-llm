output "id" {
  value = azurerm_container_app_environment.this.id
}

output "name" {
  value = azurerm_container_app_environment.this.name
}

output "log_analytics_workspace_id" {
  value = local.law_id
}

output "workload_profile_name" {
  value = local.effective_workload_profile.name
}

output "static_ip_address" {
  value = azurerm_container_app_environment.this.static_ip_address
}
