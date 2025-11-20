# Container Apps environment with optional Log Analytics integration
resource "azurerm_container_app_environment" "this" {
  name                           = "${var.environment}-acaenv"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  log_analytics_workspace_id     = local.law_id
  internal_load_balancer_enabled = var.lb_internal_only


  # https://learn.microsoft.com/en-us/azure/container-apps/workload-profiles-overview
  dynamic "workload_profile" {
    for_each = var.workload_profile.workload_profile_type == "Consumption" ? [1] : []
    content {
      name                  = var.workload_profile.name
      workload_profile_type = "Consumption"
    }
  }

  dynamic "workload_profile" {
    for_each = var.workload_profile.workload_profile_type != "Consumption" ? [1] : []
    content {
      name                  = var.workload_profile.name
      workload_profile_type = var.workload_profile.workload_profile_type
      minimum_count         = var.workload_profile.minimum_count
      maximum_count         = var.workload_profile.maximum_count
    }
  }

  tags = var.tags
}

# Disable public network access if private endpoint is being used
resource "azapi_update_resource" "container_app_env_public_network_access" {
  type        = "Microsoft.App/managedEnvironments@2024-10-02-preview"
  resource_id = azurerm_container_app_environment.this.id

  body = {
    properties = {
      publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"
    }
  }
  depends_on = [azurerm_container_app_environment.this]
}

