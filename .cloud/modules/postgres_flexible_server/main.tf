resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  zone                          = var.zone
  storage_mb                    = var.storage_mb
  storage_tier                  = var.storage_tier
  sku_name                      = var.sku_name
  backup_retention_days         = var.backup_retention_days
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  count = var.database_name != null ? 1 : 0

  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = var.collation
  charset   = var.charset
}


