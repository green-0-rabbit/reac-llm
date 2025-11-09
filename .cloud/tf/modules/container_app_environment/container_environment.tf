# Container Apps environment with optional Log Analytics integration
resource "azurerm_container_app_environment" "this" {
  name                           = "${var.environment}-acaenv"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_only
  log_analytics_workspace_id     = local.law_id

  dynamic "workload_profile" {
    for_each = local.effective_workload_profile != null && local.effective_workload_profile.workload_profile_type != "Consumption" ? [local.effective_workload_profile] : []
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  tags = var.tags
}
