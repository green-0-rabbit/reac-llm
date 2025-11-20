locals {
  law_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : (
    var.create_log_analytics ? azurerm_log_analytics_workspace.this[0].id : null
  )
}
