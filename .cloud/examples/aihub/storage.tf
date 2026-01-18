resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Security settings
  public_network_access_enabled = true
  shared_access_key_enabled     = false # Enforce RBAC

  tags = {
    env = var.env
  }
}


