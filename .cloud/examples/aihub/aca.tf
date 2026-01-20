locals {
  acr_login_server = data.azurerm_container_registry.acr.login_server
  #  backend_aihub_fqdn = "containerappdemo-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  # keycloak_fqdn      = "keycloak-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  backend_aihub_fqdn = "containerappdemo-${var.env}.${module.container_app_environment.default_domain}"
  keycloak_fqdn      = "keycloak-${var.env}.${module.container_app_environment.default_domain}"
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
    min_replicas = 1
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
            value = var.keycloak_saml_signing_cert
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_SIGNING_PRIVATE_KEY"
            value = var.keycloak_saml_signing_private_key
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

  # auth = {
  #   global_validation = {
  #     unauthenticated_client_action = "RedirectToLoginPage"
  #     excluded_paths                = ["/health", "/favicon.ico"]
  #   }
  #   identity_providers = {
  #     custom_open_id_connect_providers = {
  #       keycloak = {
  #         registration = {
  #           client_id = "api-sso"
  #           client_credential = {
  #             client_secret_setting_name = "keycloak-client-secret"
  #           }
  #           open_id_connect_configuration = {
  #             well_known_open_id_configuration = "http://${local.keycloak_fqdn}/realms/api-realm/.well-known/openid-configuration"
  #             authorization_endpoint           = "http://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/auth"
  #             token_endpoint                   = "http://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/token"
  #             issuer                           = "http://${local.keycloak_fqdn}/realms/api-realm"
  #             certification_uri                = "http://${local.keycloak_fqdn}/realms/api-realm/protocol/openid-connect/certs"
  #           }
  #         }
  #         login = {
  #           name_claim_type = "preferred_username"
  #           scopes          = ["openid", "profile", "email"]
  #         }
  #       }
  #     }
  #   }
  # }

  registry_fqdn = local.acr_login_server

  acr_id = data.azurerm_container_registry.acr.id
  kv_id  = azurerm_key_vault.this.id

  ingress = {
    external_enabled = true
    target_port      = var.app_port
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
      name  = "database-password"
      value = var.admin_password
    },
    {
      name  = "database-url"
      value = format("postgresql://%s:%s@%s:5432/%s?ssl=true", urlencode(var.postgres_administrator_login), urlencode(var.admin_password), module.postgres.fqdn, module.postgres.database_name)
    },
    {
      name  = "api-key"
      value = module.ai_foundry.primary_access_key
    },
    {
      name  = "jwt-secret"
      value = var.jwt_secret
    },
    {
      name  = "keycloak-client-secret"
      value = "supersecret"
    },
    {
      name  = "storage-connection-string"
      value = azurerm_storage_account.this.primary_connection_string
    }
  ]

  template = {
    min_replicas = 1
    containers = [
      {
        name   = "aihub-backend"
        image  = "${local.acr_login_server}/ai-hub-backend:21274"
        cpu    = 0.5
        memory = "1Gi"
        env = [
          {
            name  = "APP_NAME"
            value = var.app_name
          },
          {
            name  = "APP_PORT"
            value = var.app_port
          },
          {
            name  = "ENABLE_CORS"
            value = "true"
          },
          {
            name  = "CORS_ALLOWED_ORIGINS"
            value = var.cors_allowed_origins
          },
          {
            name  = "NODE_ENV"
            value = "production"
          },
          {
            name  = "FRONTEND_URL"
            value = var.frontend_url
          },
          {
            name        = "DATABASE_URL"
            secret_name = "database-url"
          },
          {
            name        = "AZURE_STORAGE_CONNECTION_STRING"
            secret_name = "storage-connection-string"
          },
          {
            name  = "AZURE_STORAGE_SERVICE_URI"
            value = azurerm_storage_account.this.primary_blob_endpoint
          },
          {
            name  = "AZURE_STORAGE_CONTAINER_NAME"
            value = var.storage_container_name
          },
          {
            name  = "AZURE_CLIENT_ID"
            value = azurerm_user_assigned_identity.containerapp.client_id
          },
          {
            name        = "API_KEY"
            secret_name = "api-key"
          },
          {
            name  = "API_ENDPOINT"
            value = module.ai_foundry.openai_endpoint
          },
          {
            name  = "API_MODEL_NAME"
            value = "gpt-4.1"
          },
          {
            name  = "API_VERSION"
            value = "2025-04-14"
          },
          {
            name  = "SAML_ENTRYPOINT"
            value = "https://${local.keycloak_fqdn}/realms/api-realm/protocol/saml"
          },
          {
            name  = "SAML_ISSUER"
            value = var.saml_issuer
          },
          {
            name  = "SAML_CERT"
            value = var.keycloak_saml_signing_cert
          },
          {
            name  = "SAML_PATH"
            value = "/auth/saml/callback"
          },
          {
            name        = "JWT_SECRET"
            secret_name = "jwt-secret"
          },
          {
            name  = "JWT_EXPIRES_IN"
            value = "3600s"
          },
          {
            name  = "JWT_COOKIE_NAME"
            value = "Authentication"
          },
          {
            name  = "JWT_REFRESH_COOKIE"
            value = "rt"
          },
          {
            name  = "JWT_REFRESH_EXPIRES_IN"
            value = "604800"
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
