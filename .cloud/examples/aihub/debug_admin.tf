resource "azurerm_postgresql_flexible_server_active_directory_administrator" "debug_admin_vm" {
  server_name         = module.postgres_todoapi.server_name
  resource_group_name = azurerm_resource_group.rg.name
  principal_name      = "vm-bastion-infra"
  object_id           = "691f50d3-05de-4fab-a458-54e6564a7cd1"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  principal_type      = "ServicePrincipal"
}
