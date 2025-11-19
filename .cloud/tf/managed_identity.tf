resource "azurerm_user_assigned_identity" "containerapp" {
  location            = var.location
  name                = "acami-${var.env}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
}
