locals {
  acr_login_server = data.azurerm_container_registry.acr.login_server
  #  backend_aihub_fqdn = "containerappdemo-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  # keycloak_fqdn      = "keycloak-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  backend_aihub_fqdn  = "containerappdemo-${var.env}.${module.container_app_environment.default_domain}"
  keycloak_fqdn       = "keycloak-${var.env}.${module.container_app_environment.default_domain}"
  frontend_aihub_fqdn = "ai-hub-frontend-${var.env}.${module.container_app_environment.default_domain}"
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
    max_replicas = 1
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
            value = "https://${local.frontend_aihub_fqdn}/*"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_REDIRECT_URIS"
            value = "https://${local.backend_aihub_fqdn}/*"
          },
          {
            name  = "KC_REALM_AIHUB-PROD_WEB_ORIGINS"
            value = ""
          },
          {
            name  = "KC_REALM_AIHUB-PROD_SAML_IDP_INITIATED_SSO_URL_NAME"
            value = "aihub-prod"
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
      value = format("postgresql://%s:%s@%s:5432/%s?schema=aihub", urlencode(var.postgres_administrator_login), urlencode(var.admin_password), module.postgres.fqdn, module.postgres.database_name)
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
    max_replicas = 1
    containers = [
      {
        name   = "aihub-backend"
        image  = "${local.acr_login_server}/ai-hub-backend:21274"
        cpu    = 0.5
        memory = "1Gi"
        command = [
          "/bin/sh",
          "-c",
          <<-EOF
          echo "Patching: Creating unaccent extension..."
          echo "CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA aihub;" | npx prisma db execute --stdin --url "$DATABASE_URL"
          ./entrypoint.sh
          EOF
        ]
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
            value = "https://${local.frontend_aihub_fqdn}"
          },
          {
            name  = "NODE_ENV"
            value = "production"
          },
          {
            name  = "FRONTEND_URL"
            value = "https://${local.frontend_aihub_fqdn}"
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
            name  = "AZURE_STORAGE_CONTAINER_NAME"
            value = azurerm_storage_container.this.name
          },
          {
            name  = "AZURE_STORAGE_SERVICE_URI"
            value = azurerm_storage_account.this.primary_blob_endpoint
          },
          {
            name  = "AZURE_STORAGE_DOWNLOAD_URL"
            value = trimsuffix(azurerm_storage_account.this.primary_blob_endpoint, "/")
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
            value = "gpt-4.1-GlobalStandard"
          },
          {
            name  = "API_VERSION"
            value = "2024-10-21"
          },
          {
            name  = "SAML_ENTRYPOINT"
            value = "https://${local.keycloak_fqdn}/realms/api-realm/protocol/saml/clients/aihub-prod"
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
            value = "7200"
          },
          {
            name  = "JWT_COOKIE_NAME"
            value = "at"
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

module "frontend_aihub" {
  source = "../../modules/container_app"

  app_config = {
    name                  = "ai-hub-frontend"
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

  registry_fqdn = local.acr_login_server
  acr_id        = data.azurerm_container_registry.acr.id
  kv_id         = azurerm_key_vault.this.id

  ingress = {
    external_enabled = true
    target_port      = 8080
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  secrets                    = []
  create_acr_role_assignment = false

  template = {
    min_replicas = 1
    max_replicas = 1
    volumes = [
      {
        name         = "nginx-conf"
        storage_type = "EmptyDir"
      },
      {
        name         = "nginx-run"
        storage_type = "EmptyDir"
      },
      {
        name         = "nginx-cache"
        storage_type = "EmptyDir"
      }
    ]
    containers = [
      {
        name   = "ai-hub-frontend"
        image  = "${local.acr_login_server}/ai-hub-frontend:21624"
        cpu    = 0.5
        memory = "1Gi"
        command = [
          "/bin/sh",
          "-c",
          <<-EOF
          cp -r /usr/share/nginx/html /tmp/html
          find /tmp/html -type f -print0 | xargs -0 sed -i 's|api-aihub.lab-iwm.com|'$API_DOMAIN'|g'
          cat <<NGINX > /etc/nginx/conf.d/default.conf
          server {
              listen 8080;
              listen [::]:8080;
              server_tokens off;
              root /tmp/html;
              index index.html index.htm;
              location = /index.html {
                  internal;
                  add_header Cache-Control 'no-store';
                  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
              }
              location / {
                  try_files \$uri \$uri/ /index.html;
              }
              error_page 500 502 503 504 /50x.html;
              location = /50x.html {
                  root /tmp/html;
              }
          }
          NGINX
          nginx -g 'daemon off;'
          EOF
        ]
        env = [
          {
            name  = "API_URL"
            value = "https://${local.backend_aihub_fqdn}"
          },
          {
            name  = "API_DOMAIN"
            value = local.backend_aihub_fqdn
          },
          {
            name  = "PORT"
            value = "8080"
          },
          {
            name  = "NGINX_PORT"
            value = "8080"
          }
        ]
        volume_mounts = [
          {
            name = "nginx-conf"
            path = "/etc/nginx/conf.d"
          },
          {
            name = "nginx-run"
            path = "/var/run"
          },
          {
            name = "nginx-cache"
            path = "/var/cache/nginx"
          }
        ]
      }
    ]
  }
}

module "frontend_aihub_fix" {
  source = "../../modules/container_app"

  app_config = {
    name                  = "ai-hub-frontend-fix"
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

  registry_fqdn = local.acr_login_server
  acr_id        = data.azurerm_container_registry.acr.id
  kv_id         = azurerm_key_vault.this.id

  ingress = {
    external_enabled = true
    target_port      = 8080
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  secrets                    = []
  create_acr_role_assignment = false

  template = {
    min_replicas = 1
    max_replicas = 1
    containers = [
      {
        name   = "ai-hub-frontend-fix"
        image  = "humaapi0registry/frontend-demo-fix:latest"
        cpu    = 0.5
        memory = "1Gi"
        env = [
          {
            name  = "API_URL"
            value = "https://${local.backend_aihub_fqdn}"
          },
          {
            name  = "SESSION_REPLAY_KEY"
            value = ""
          },
          {
            name  = "PIANO_ANALYTICS_SITE_ID"
            value = ""
          },
          {
            name  = "PIANO_ANALYTICS_COLLECTION_DOMAIN"
            value = ""
          }
        ]
      }
    ]
  }
}

module "todo_app_api" {
  source = "../../modules/container_app"

  app_config = {
    name                  = "todo-app-api"
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
    external_enabled = true
    target_port      = 3001
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  secrets = [
    {
      name  = "database-password"
      value = var.admin_password
    }
  ]

  template = {
    min_replicas = 1
    max_replicas = 1
    containers = [
      {
        name   = "todo-app-api"
        # Placeholder image - user needs to build this
        image  = "humaapi0registry/todo-app-api:latest"
        cpu    = 0.5
        memory = "1Gi"
        env = [
          {
            name  = "PORT"
            value = "3001"
          },
          {
            name  = "NODE_ENV"
            value = "prod"
          },
          # Database Configuration
          {
            name  = "DATABASE_HOST"
            value = module.postgres.fqdn
          },
          {
            name  = "DATABASE_PORT"
            value = "5432"
          },
          {
            name  = "DATABASE_SCHEMA"
            value = "public"
          },
          {
            name  = "DATABASE_USERNAME"
            value = var.postgres_administrator_login
          },
          {
            name        = "DATABASE_PASSWORD"
            secret_name = "database-password"
          },
           # Storage Configuration (Managed Identity)
          {
            name  = "AZURE_STORAGE_SERVICE_URI"
            value = azurerm_storage_account.this.primary_blob_endpoint
          },
          {
            name  = "AZURE_STORAGE_CONTAINER_NAME"
            value = "todo-app-container"
          },
          {
             name = "AZURE_CLIENT_ID"
             value = azurerm_user_assigned_identity.containerapp.client_id
          },
          # AI Foundry Configuration (Managed Identity)
          {
            name  = "API_ENDPOINT"
            value = module.ai_foundry.openai_endpoint
          },
          {
            name  = "API_MODEL_NAME"
            value = "gpt-4.1-GlobalStandard" 
          },
          {
            name  = "API_VERSION"
            value = "2024-10-21"
          }
        ]
      }
    ]
  }
}

resource "azurerm_role_assignment" "openai_user" {
  scope                = module.ai_foundry.ai_foundry_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
}
