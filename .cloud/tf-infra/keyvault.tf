resource "azurerm_key_vault" "env" {
  for_each = toset(var.environments)

  name                        = "${var.project}-kv-${each.value}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.env[each.value].name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  rbac_authorization_enabled  = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  tags = {
    project = var.project
    env     = each.value
  }
}


