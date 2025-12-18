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

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = local.container_app_fqdn
    organization = "My Org"
  }

  dns_names = [local.container_app_fqdn]

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "cert_signing",
    "crl_signing",
  ]
}

resource "local_file" "cert_pem" {
  content  = tls_self_signed_cert.example.cert_pem
  filename = "${path.module}/temp/cert.pem"
}

resource "local_file" "key_pem" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/temp/key.pem"
}

resource "terraform_data" "pfx" {
  triggers_replace = [
    tls_self_signed_cert.example.cert_pem,
    tls_private_key.example.private_key_pem
  ]

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/temp && openssl pkcs12 -export -out ${path.module}/temp/cert.pfx -inkey ${path.module}/temp/key.pem -in ${path.module}/temp/cert.pem -passout pass:"
  }
}

resource "terraform_data" "der" {
  triggers_replace = [
    tls_self_signed_cert.example.cert_pem
  ]

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/temp && openssl x509 -in ${path.module}/temp/cert.pem -outform DER -out ${path.module}/temp/cert.der"
  }
}

data "local_file" "pfx" {
  filename   = "${path.module}/temp/cert.pfx"
  depends_on = [terraform_data.pfx]
}

data "local_file" "der" {
  filename   = "${path.module}/temp/cert.der"
  depends_on = [terraform_data.der]
}

resource "azurerm_key_vault_secret" "containerapp_cert_v2" {
  name         = "containerapp-cert-v2"
  value        = data.local_file.pfx.content_base64
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pkcs12"
}


