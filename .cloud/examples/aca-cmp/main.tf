locals {
  acr_login_server   = data.azurerm_container_registry.acr.login_server
  container_app_fqdn = "containerappdemo-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
  keycloak_fqdn      = "keycloak-${var.env}.${data.azurerm_private_dns_zone.sbx.name}"
}

module "vnet-spoke1" {
  source = "../../modules/vnet"

  # By default, this module will create a resource group, proivde the name here
  # to use an existing resource group, specify the existing resource group name,
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  resource_group_name                        = azurerm_resource_group.rg.name
  location                                   = var.location
  vnet_name                                  = var.spoke_vnet_name
  remote_virtual_network_id                  = data.azurerm_virtual_network.hub-vnet.id
  remote_virtual_network_name                = data.azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_resource_group_name = var.main_rg_name
  enable_peering                             = true

  # Provide valid VNet Address space for spoke virtual network.  
  vnet_address_space = var.spoke_vnet_address_space

  # Private DNS zones to link with this VNet
  private_dns_zone_resource_group_name = var.main_rg_name

  private_dns_zone_names = concat([
    data.azurerm_private_dns_zone.sbx.name,
    data.azurerm_private_dns_zone.keyvault.name,
    data.azurerm_private_dns_zone.storage.name,
    data.azurerm_private_dns_zone.acr.name,
    data.azurerm_private_dns_zone.postgres.name,
  ], values(data.azurerm_private_dns_zone.monitor)[*].name)


  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # Route_table and NSG association to be added automatically for all subnets listed here.
  subnets = var.spoke_vnet_subnets

  tags = {
    project-name = "sbx-${var.env}-kag"
  }
}

module "container_app_environment" {
  source                     = "../../modules/container_app_environment"
  name                       = "acaenvdemo-${var.env}"
  env                        = var.env
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  infrastructure_subnet_id   = module.vnet-spoke1.subnet_ids["ACASubnet"]
  logs_destination           = "azure-monitor"
  log_analytics_workspace_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.this[0].id

  # @see https://learn.microsoft.com/en-us/azure/container-apps/workload-profiles-overview
  workload_profile = {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  certificate_config = {
    name                    = "containerapp-cert"
    certificate_blob_base64 = data.azurerm_key_vault_secret.containerapp_cert.value
  }

  tags = var.tags
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

  custom_domain = {
    name                     = local.keycloak_fqdn
    certificate_binding_type = "SniEnabled"
    certificate_id           = module.container_app_environment.certificate_id
  }

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
            value = "https://${local.container_app_fqdn}/*"
          }
        ]
      }
    ]
  }
}

module "container_app" {
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

  custom_domain = {
    name                     = local.container_app_fqdn
    certificate_binding_type = "SniEnabled"
    certificate_id           = module.container_app_environment.certificate_id
  }

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
        name  = "todo-app-api"
        image = "${local.acr_login_server}/local/todo-app-api:latest"
        # image = "${local.acr_login_server}/wbitt/network-multitool:alpine-extra"
        # image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
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



