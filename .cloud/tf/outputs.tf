# Handy outputs
output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault ID for the environment."
}

output "storage_account_name" {
  value       = azurerm_storage_account.this.name
  description = "Name of the infrastructure storage account."
}
