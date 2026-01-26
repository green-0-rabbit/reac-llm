resource "azurerm_container_app_environment" "this" {
  name                               = var.name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  infrastructure_subnet_id           = var.infrastructure_subnet_id
  log_analytics_workspace_id         = var.logs_destination == "log-analytics" ? var.log_analytics_workspace_id : null
  internal_load_balancer_enabled     = var.lb_internal_only
  public_network_access              = var.public_network_access_enabled ? "Enabled" : "Disabled"
  infrastructure_resource_group_name = var.infrastructure_resource_group_name != null ? var.infrastructure_resource_group_name : "aca-${var.env}-rg"
  

  logs_destination = var.logs_destination

  workload_profile {
    name                  = var.workload_profile.name
    workload_profile_type = var.workload_profile.workload_profile_type
    minimum_count         = var.workload_profile.workload_profile_type == "Consumption" ? null : var.workload_profile.minimum_count
    maximum_count         = var.workload_profile.workload_profile_type == "Consumption" ? null : var.workload_profile.maximum_count
  }

  tags = var.tags
}

resource "azurerm_container_app_environment_certificate" "this" {
  count                        = var.certificate_config != null ? 1 : 0
  name                         = var.certificate_config.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  certificate_blob_base64      = var.certificate_config.certificate_blob_base64
  certificate_password         = var.certificate_config.certificate_password
}

# https://learn.microsoft.com/en-us/azure/container-apps/log-options
resource "azurerm_monitor_diagnostic_setting" "cae_to_law" {
  count = var.logs_destination == "azure-monitor" ? 1 : 0

  name                       = "diag-${var.name}-law"
  target_resource_id         = azurerm_container_app_environment.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Common categories for Container Apps Environment diagnostics
  enabled_log { category = "ContainerAppConsoleLogs" }
  enabled_log { category = "ContainerAppSystemLogs" }

  enabled_metric {
    category = "AllMetrics"
  }
}


