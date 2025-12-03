output "id" {
  value = azurerm_container_app_environment.this.id
}

output "name" {
  value = azurerm_container_app_environment.this.name
}

output "log_analytics_workspace_id" {
  value = var.log_analytics_workspace_id
}

output "workload_profile_name" {
  value = var.workload_profile.name
}

output "static_ip_address" {
  value = azurerm_container_app_environment.this.static_ip_address
}

output "certificate_id" {
  value = var.certificate_config != null ? azurerm_container_app_environment_certificate.this[0].id : null
}
