module "postgres" {
  source = "../../modules/postgres_flexible_server"

  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  server_name            = "psql-${var.env}-${var.project}"
  administrator_login    = var.postgres_administrator_login
  administrator_password = var.admin_password
  storage_mb             = 32768
  storage_tier           = "P4"
  sku_name               = "B_Standard_B1ms"
  postgres_version       = "17"
  zone                   = "1"

  public_network_access_enabled = true

  # delegated_subnet_id = module.vnet-spoke1.subnet_ids["PostgresSubnet"]
  # private_dns_zone_id = data.azurerm_private_dns_zone.postgres.id

  database_name = "aihub"

  authentication = {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = var.tags
}


resource "azurerm_postgresql_flexible_server_active_directory_administrator" "aad_admin" {
  server_name         = module.postgres.server_name
  resource_group_name = azurerm_resource_group.rg.name
  principal_name      = azurerm_user_assigned_identity.containerapp.name
  object_id           = azurerm_user_assigned_identity.containerapp.principal_id
  tenant_id           = data.azurerm_client_config.current.tenant_id
  principal_type      = "ServicePrincipal"
}


resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  name             = "allow-all"
  server_id        = module.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
