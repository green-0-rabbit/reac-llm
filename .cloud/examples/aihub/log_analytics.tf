resource "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics_workspace_id == "" && var.create_log_analytics ? 1 : 0
  name                = "${var.project}-laws-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
# https://learn.microsoft.com/en-us/azure/azure-monitor/logs/private-link-configure
resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "${var.resource_group_name}-ampls"
  resource_group_name = azurerm_resource_group.rg.name

  ingestion_access_mode = "PrivateOnly"

}

resource "azurerm_monitor_private_link_scoped_service" "law_link" {
  name                = "${azurerm_log_analytics_workspace.this[0].name}-law-to-ampls"
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.this[0].id
}
