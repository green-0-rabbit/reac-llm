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
  value = (
    var.certificate_config != null
    ? azurerm_container_app_environment_certificate.this[var.certificate_config.name].id
    : (
      length(var.certificate_configs) > 0
      ? azurerm_container_app_environment_certificate.this[var.certificate_configs[0].name].id
      : null
    )
  )
}

output "certificate_ids" {
  value = {
    for name, cert in azurerm_container_app_environment_certificate.this : name => cert.id
  }
}

output "logs_destination" {
  value = var.logs_destination
}

output "diagnostic_setting_id" {
  value = var.logs_destination == "azure-monitor" ? azurerm_monitor_diagnostic_setting.cae_to_law[0].id : null
}
output "default_domain" {
  value = azurerm_container_app_environment.this.default_domain
}
