resource "azurerm_key_vault" "this" {

  name                        = "kv-${var.env}-kag"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  rbac_authorization_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  tags = {
    env = var.env
  }
}


