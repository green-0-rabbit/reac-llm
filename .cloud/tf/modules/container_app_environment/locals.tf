locals {
  law_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : (
    var.create_log_analytics ? azurerm_log_analytics_workspace.this[0].id : null
  )

  default_workload_profile = {
    name                  = "consumption"
    workload_profile_type = "Consumption"
    minimum_count         = null
    maximum_count         = null
  }

  merged_workload_profile = var.workload_profile != null ? merge(local.default_workload_profile, var.workload_profile) : local.default_workload_profile

  effective_workload_profile = local.merged_workload_profile.workload_profile_type == "Consumption" ? merge(local.merged_workload_profile, {
    minimum_count = null
    maximum_count = null
  }) : local.merged_workload_profile
}
