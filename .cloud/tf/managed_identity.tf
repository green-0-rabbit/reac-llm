resource "azurerm_user_assigned_identity" "containerapp" {
  location            = var.location
  name                = "acami-${var.env}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "containerapp" {
  scope                = data.azurerm_subnet.aca.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
}
