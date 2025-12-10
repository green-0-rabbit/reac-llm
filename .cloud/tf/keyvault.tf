resource "azurerm_key_vault" "this" {

  name                        = "kv-${var.env}-kag"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  rbac_authorization_enabled = true

  # network_acls {
  #   bypass         = "AzureServices"
  #   default_action = "Deny"
  #   ip_rules       = [var.current_ip]
  # }

  tags = {
    env = var.env
  }
}

resource "azurerm_key_vault_certificate" "containerapp" {
  name         = "containerapp-cert"
  key_vault_id = azurerm_key_vault.this.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = [local.container_app_fqdn]
      }

      subject            = "CN=${local.container_app_fqdn}"
      validity_in_months = 12
    }
  }
}


