output "id" {
  description = "The ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "administrator_login" {
  description = "The administrator login of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}

output "database_name" {
  description = "The name of the default database created."
  value       = var.database_name != null ? azurerm_postgresql_flexible_server_database.this[0].name : null
}

output "database_id" {
  description = "The ID of the default database created."
  value       = var.database_name != null ? azurerm_postgresql_flexible_server_database.this[0].id : null
}
