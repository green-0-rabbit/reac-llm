module "postgres" {
  source = "../modules/postgres_flexible_server"

  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  server_name            = "psql-${var.env}-todo-app"
  administrator_login    = var.postgres_administrator_login
  administrator_password = var.admin_password
  storage_mb             = 32768
  storage_tier           = "P4"
  sku_name               = "B_Standard_B1ms"
  postgres_version       = "17"
  zone                   = "1"

  delegated_subnet_id = module.vnet-spoke1.subnet_ids["PostgresSubnet"]
  private_dns_zone_id = data.azurerm_private_dns_zone.postgres.id

  database_name = "todo_app"

  tags = var.tags
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.this.id
}
