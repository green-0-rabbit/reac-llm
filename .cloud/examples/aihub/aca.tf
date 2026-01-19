locals {
  acr_login_server   = data.azurerm_container_registry.acr.login_server
  #  backend_aihub_fqdn = "containerappdemo-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  # keycloak_fqdn      = "keycloak-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  backend_aihub_fqdn = "containerappdemo.${module.container_app_environment.default_domain}"
  keycloak_fqdn      = "keycloak.${module.container_app_environment.default_domain}"
}




#  Example https://github.com/Azure/terraform-azure-container-apps/blob/v0.4.0/examples/acr/main.tf
# Check this https://github.com/thomast1906/thomasthorntoncloud-examples/tree/master/Azure-Container-App-Terraform/Terraform
module "keycloak" {
  source = "../../modules/container_app"

  app_config = {
    name                  = "keycloak"
    revision_mode         = "Single"
    workload_profile_name = module.container_app_environment.workload_profile_name
  }
  environment                  = var.env
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = module.container_app_environment.id

  user_assigned_identity = {
    id           = azurerm_user_assigned_identity.containerapp.id
    principal_id = azurerm_user_assigned_identity.containerapp.principal_id
  }

  create_acr_role_assignment = false

  registry_fqdn = local.acr_login_server
  acr_id        = data.azurerm_container_registry.acr.id
  kv_id         = azurerm_key_vault.this.id

  ingress = {
    allow_insecure_connections = true
    external_enabled           = true
    target_port                = 8080
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  # custom_domain = {
  #   name = local.keycloak_fqdn
  # }

  secrets = [
    {
      name  = "admin-password"
      value = var.admin_password
    },
    {
      name  = "api-sso-secret"
      value = "supersecret"
    },
    {
      name  = "test-user-password"
      value = "userpass1234#!"
    }
  ]

  template = {
    containers = [
      {
        name   = "keycloak"
        image  = "humaapi0registry/keycloak:latest"
        cpu    = 1.0
        memory = "2Gi"
        args   = ["start-dev", "--import-realm"]
        env = [
          {
            name  = "KC_HOSTNAME"
            value = local.keycloak_fqdn
          },
          {
            name  = "KEYCLOAK_ADMIN"
            value = "admin"
          },
          {
            name        = "KEYCLOAK_ADMIN_PASSWORD"
            secret_name = "admin-password"
          },
          {
            name  = "KC_PROXY_HEADERS"
            value = "xforwarded"
          },
          {
            name  = "KC_HTTP_ENABLED"
            value = "true"
          },
          {
            name  = "KC_HOSTNAME_STRICT"
            value = "false"
          },
          {
            name  = "KC_HOSTNAME_STRICT_HTTPS"
            value = "false"
          },
          {
            name  = "KC_LOG_LEVEL"
            value = "DEBUG"
          },
          {
            name        = "KC_REALM_API-SSO_SECRET"
            secret_name = "api-sso-secret"
          },
          {
            name        = "KC_TEST_USER_PASSWORD"
            secret_name = "test-user-password"
          },
          {
            name  = "KC_REALM_API-SSO_REDIRECT_URIS"
            value = "https://${local.backend_aihub_fqdn}/*"
          },
          {
            name  = "KC_HEALTH_ENABLED"
            value = "true"
          },
          {
            name  = "KC_METRICS_ENABLED"
            value = "true"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_ASSERTION_CONSUMER_URL_REDIRECT"
            value = "https://${local.backend_aihub_fqdn}/auth/saml/callback"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_SINGLE_LOGOUT_SERVICE_URL_POST"
            value = "https://${local.backend_aihub_fqdn}/auth/logout"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_ASSERTION_CONSUMER_URL_POST"
            value = "https://${local.backend_aihub_fqdn}/auth/saml/callback"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_SINGLE_LOGOUT_SERVICE_URL_REDIRECT"
            value = "https://${local.backend_aihub_fqdn}/auth/logout"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_SIGNING_CERTIFICATE"
            value = "MIIDCTCCAfGgAwIBAgIURK6kIm/e1o7c5dwTKuNB2BToNYYwDQYJKoZIhvcNAQELBQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI2MDExOTE5MjUxOVoXDTI3MDExOTE5MjUxOVowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuQlFxVQrFXtYU3TtyKVoqhJrrcvFMWxGUZ5IoxK6WCfjMDr4J8DIkTL20TjKUJm7sTBoYNA7dsZXhBUJUqipBhB4LDzF9MmJhZX5PXLIYNhTwzKo6FF05ETroWfTMLohC0SpXsKc4+kjsXFymyoLeO0/5woskCAE7DLIp7Mg1copxS+ZaHZJjo7iFiJe/EJxuHzAVQihOTWZtptUPIz3ZynzfP/DhW4hhlLBW5IibcVe0GTzRU6OFmPqo+HJMPv8xXIfvA95RiK2fjJXhdxV5wN8KhDfCh2/39uk++drapiT9A00D5KAsPWZDq5Qq11eEEiLT3B7O5FSPPabqR4U7wIDAQABo1MwUTAdBgNVHQ4EFgQUJ58wvgxovtA2hQ7wPPX4nap/wvUwHwYDVR0jBBgwFoAUJ58wvgxovtA2hQ7wPPX4nap/wvUwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEALE5jz4y4L1u2Ibdn8ql49OXqPUNnfRZNDvaMtu2V/+npZu29QcdQqjfz/LmszR9oaMmJ7t8QzTvhfRZneOPwyvESjsQPPWGe3VDXXIFuwsOOQMEQWwUKSbfVWl94FrQkuiskshSGrU3MKrrZ6D6qBnYISQ1Azt9fDd7QXsqYttKaDWAMfC5xAUW+0zionlqFSva4MsL9SKLYZhu58rGnLwXad3UEbwCODKZrqsbvf4N0mI2Hwgm7u6bmBk/CmVPzr2/GPNjSkKjNsNz1Zt9AlyatKwKfLb9NKprZ9116rtYm/taIT/34ZbHGSfMHhEtEjMcKlSLxZg59MUj/9Qdmaw=="
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_SIGNING_PRIVATE_KEY"
            value = "MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC5CUXFVCsVe1hTdO3IpWiqEmuty8UxbEZRnkijErpYJ+MwOvgnwMiRMvbROMpQmbuxMGhg0Dt2xleEFQlSqKkGEHgsPMX0yYmFlfk9cshg2FPDMqjoUXTkROuhZ9MwuiELRKlewpzj6SOxcXKbKgt47T/nCiyQIATsMsinsyDVyinFL5lodkmOjuIWIl78QnG4fMBVCKE5NZm2m1Q8jPdnKfN8/8OFbiGGUsFbkiJtxV7QZPNFTo4WY+qj4ckw+/zFch+8D3lGIrZ+MleF3FXnA3wqEN8KHb/f26T752tqmJP0DTQPkoCw9ZkOrlCrXV4QSItPcHs7kVI89pupHhTvAgMBAAECggEAAxERG8r1fIF9qRhu2RygsPI64E0DGNAYvuvhe/kTUeMLWWEeJsPZBHW0myrBSPewoX2nZTSzn5gm8Cn3FxceLLBjhXwrsw8PXUGV5BD9xYPK/kOzLUfYU5uEJOSByV90V773aE96ZoPr0wTfJ4zZVtORHmT6mxg6F1NkzvQMOcQniNAhuBlU8fDqC/Jsqp/cUN7ykWiTggRDznRiulMorlLe9GxJ2WUNjamElSbVgctvza35o5QrfYGGQ6ighSDr29C8aXREat6RgkhEZpaxa2cOdLoknhBmvU5vxof1gplpucYKs2FR7RK3ZSki8ILvoxhsT6EdwSdHCORhtHAxFQKBgQD4o8JfiC0yhTdMLs0N84y573RGUL5HBKFEnG+u3F34rTAe6ao4E8fOc2gRZXV5hxx0ZNX2tht642KUGZ5UESkvVFDjpVcoPo1xcLIgLVAU20IPsNfWyOwYorJh0sHvQm6X2cDYfJnzAqngaaY8UOKoUUeR/U9aruijHIhat+f42wKBgQC+g4N9x4aiYjENjLd+ludiXwcdvP/GmfrwaQrhlaI1GMA3fyAOpDqCCylS0sclHogrt+93YY9K5hZ8j6GnEeRnXv+iaZoPeak23i3+0F/xM942Hn9iKU5gFvoa02rY2S+uwIPyl4/fpeUp7FwojHmnUn46AXYpFrAaca9wUcBWfQKBgFqb+vqreqUdjQBTUeDSr6cWz03MoPrqggap571Wi1xTaOTrDGAxPTBMOFGWos/t3/2+vYaR6MPI16TXDS7frh2UYYIEQBXnbc444XoGBYdyn5pQnQxD/2aJEsDMcBha2I+1sqm16QvQfNV8VwUHbzC3AqQ9Xu7J1aUv/2uUMfhnfAoGAC8vk5nLmWUOvOeGOsx3w8dxkemjrhYafTSeT7ufvBU6lCEqs13s/zDGYu3IltpyvXdWj1EaMMt0QY2IZZljrRaNSPOJBEdg8rBMR0gdhCXRmu/8jcBaSrcx+bA7PPOIl27I7+Vd9JyIEkJX8Ft6r4bpv6nOQt3aaLOkBLflB6ZkCgYBFfXA39C8ihpBlfWoNeMd7INSNuTBUM+N7UI4laTvk44jRK45YxIapcY98SWfdJkZOmo76v2fSsc90dn0r0jar30NQCMPQB3Af2AOFtDWQtQ8ENi3MfUXRLh8YZ2MRqwlSyRMUTFX0zEciLWd53Q2BSyfnKFw5hoUA4RtL9wAbIA=="
          }
        ]
      }
    ]
  }
}

module "backend_aihub" {
  source = "../../modules/container_app"

  app_config = {
    name                  = "containerappdemo"
    revision_mode         = "Single"
    workload_profile_name = module.container_app_environment.workload_profile_name
  }
  environment                  = var.env
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = module.container_app_environment.id

  user_assigned_identity = {
    id           = azurerm_user_assigned_identity.containerapp.id
    principal_id = azurerm_user_assigned_identity.containerapp.principal_id
  }

  auth = {
    global_validation = {
      unauthenticated_client_action = "RedirectToLoginPage"
      excluded_paths                = ["/health", "/favicon.ico"]
    }
    identity_providers = {
      custom_open_id_connect_providers = {
        keycloak = {
          registration = {
            client_id = "api-sso"
            client_credential = {
              client_secret_setting_name = "keycloak-client-secret"
            }
            open_id_connect_configuration = {
              well_known_open_id_configuration = "http://${local.keycloak_fqdn}/realms/api-realm/.well-known/openid-configuration"
              authorization_endpoint           = "http://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/auth"
              token_endpoint                   = "http://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/token"
              issuer                           = "http://${local.keycloak_fqdn}/realms/api-realm"
              certification_uri                = "http://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/certs"
            }
          }
          login = {
            name_claim_type = "preferred_username"
            scopes          = ["openid", "profile", "email"]
          }
        }
      }
    }
  }

  registry_fqdn = local.acr_login_server

  acr_id = data.azurerm_container_registry.acr.id
  kv_id  = azurerm_key_vault.this.id

  ingress = {
    external_enabled = true
    target_port      = 3000
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  # custom_domain = {
  #   name = local.backend_aihub_fqdn
  # }

  secrets = [
    {
      name                = "database-password"
      value               = var.admin_password
      key_vault_secret_id = azurerm_key_vault_secret.database_password.id
    },
    {
      name  = "keycloak-client-secret"
      value = "supersecret"
    }
  ]

  template = {
    containers = [
      {
        name   = "todo-app-api"
        image  = "${local.acr_login_server}/ai-hub-backend:21274"
        cpu    = 0.5
        memory = "1Gi"
        env = [
          {
            name        = "DATABASE_PASSWORD"
            secret_name = "database-password"
          },
          {
            name  = "PORT"
            value = "3000"
          },
          {
            name  = "DATABASE_HOST"
            value = module.postgres.fqdn
          },
          {
            name  = "DATABASE_PORT"
            value = "5432"
          },
          {
            name  = "DATABASE_USERNAME"
            value = module.postgres.administrator_login
          },
          {
            name  = "DATABASE_SCHEMA"
            value = module.postgres.database_name
          },
          {
            name  = "DATABASE_SSL"
            value = "true"
          },
          {
            name  = "NODE_ENV"
            value = "prod"
          },
          {
            name  = "AZURE_STORAGE_SERVICE_URI"
            value = azurerm_storage_account.this.primary_blob_endpoint
          },
          {
            name  = "AZURE_STORAGE_CONTAINER_NAME"
            value = "todo-attachments"
          },
          {
            name  = "AZURE_CLIENT_ID"
            value = azurerm_user_assigned_identity.containerapp.client_id
          },
          {
            name  = "AUTH_ISSUER_URL"
            value = "https://${local.keycloak_fqdn}/realms/api-realm"
          },
          {
            name  = "AUTH_JWKS_URI"
            value = "https://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/certs"
          },
          # {
          #   name  = "NODE_TLS_REJECT_UNAUTHORIZED"
          #   value = "0"
          # }
        ]
      }
    ]
  }

  depends_on = [
    azurerm_role_assignment.kv_secrets_user
  ]
}
