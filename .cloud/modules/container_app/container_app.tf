# Container App definition with optional registry integration
resource "azurerm_container_app" "app" {
  name                         = "${var.app_config.name}-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = var.app_config.revision_mode
  workload_profile_name        = var.app_config.workload_profile_name

  # https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/manage-user-assigned-managed-identities-azure-portal
  identity {
    type         = var.user_assigned_identity != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.user_assigned_identity != null ? [var.user_assigned_identity.id] : null
  }

  dynamic "secret" {
    for_each = var.secrets
    content {
      name                = secret.value.name
      value               = secret.value.value
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = (secret.value.key_vault_secret_id != null && var.user_assigned_identity != null) ? var.user_assigned_identity.id : null
    }
  }

  dynamic "ingress" {
    for_each = var.ingress == null ? [] : [var.ingress]
    content {
      allow_insecure_connections = ingress.value.allow_insecure_connections
      external_enabled           = ingress.value.external_enabled
      target_port                = ingress.value.target_port
      transport                  = ingress.value.transport

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight
        content {
          latest_revision = traffic_weight.value.latest_revision
          label           = traffic_weight.value.label
          percentage      = traffic_weight.value.percentage
        }
      }
    }
  }

  registry {
    server   = var.registry_fqdn
    identity = var.user_assigned_identity != null ? var.user_assigned_identity.id : "system"
  }

  template {
    dynamic "container" {
      for_each = {
        for index, container in var.template.containers : index => container
      }
      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        command = container.value.command
        args    = container.value.args

        dynamic "env" {
          for_each = {
            for index, env_item in coalesce(container.value.env, []) : index => env_item
          }
          content {
            name        = env.value.name
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }
      }
    }

    min_replicas = var.template.min_replicas
    max_replicas = var.template.max_replicas
  }

  tags = var.tags
  depends_on = [
    azurerm_role_assignment.acr_pull_uai
  ]

}

resource "azurerm_container_app_custom_domain" "custom_domain" {
  count = var.custom_domain != null ? 1 : 0

  container_app_id                         = azurerm_container_app.app.id
  name                                     = var.custom_domain.name
  certificate_binding_type                 = var.custom_domain.certificate_binding_type
  container_app_environment_certificate_id = var.custom_domain.certificate_id
}

resource "azurerm_role_assignment" "acr_pull_uai" {
  count                = (var.user_assigned_identity != null && var.create_acr_role_assignment) ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.user_assigned_identity.principal_id
}

resource "azurerm_role_assignment" "acr_pull_system" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.app.identity[0].principal_id
}

resource "azapi_resource" "auth_config" {
  count     = var.auth != null ? 1 : 0
  type      = "Microsoft.App/containerApps/authConfigs@2024-03-01"
  name      = "current"
  parent_id = azurerm_container_app.app.id

  body = {
    properties = {
      platform = {
        enabled = true
      }
      globalValidation = {
        unauthenticatedClientAction = var.auth.global_validation.unauthenticated_client_action
        excludedPaths               = var.auth.global_validation.excluded_paths
      }
      identityProviders = {
        azureActiveDirectory = var.auth.identity_providers.azure_active_directory != null ? {
          registration = {
            clientId                = var.auth.identity_providers.azure_active_directory.registration.client_id
            clientSecretSettingName = var.auth.identity_providers.azure_active_directory.registration.client_secret_setting_name
            openIdIssuer            = "https://sts.windows.net/${var.auth.identity_providers.azure_active_directory.tenant_id}/v2.0"
          }
          validation = {
            allowedAudiences = [
              "api://${var.auth.identity_providers.azure_active_directory.registration.client_id}"
            ]
          }
        } : null
        customOpenIdConnectProviders = var.auth.identity_providers.custom_open_id_connect_providers != null ? {
          for k, v in var.auth.identity_providers.custom_open_id_connect_providers : k => {
            enabled = try(v.enabled, null)
            registration = v.registration == null ? null : {
              clientId = try(v.registration.client_id, null)
              clientCredential = v.registration.client_credential == null ? null : {
                method                  = try(v.registration.client_credential.method, null)
                clientSecretSettingName = try(v.registration.client_credential.client_secret_setting_name, null)
              }
              openIdConnectConfiguration = v.registration.open_id_connect_configuration == null ? null : {
                authorizationEndpoint        = try(v.registration.open_id_connect_configuration.authorization_endpoint, null)
                tokenEndpoint                = try(v.registration.open_id_connect_configuration.token_endpoint, null)
                issuer                       = try(v.registration.open_id_connect_configuration.issuer, null)
                certificationUri             = try(v.registration.open_id_connect_configuration.certification_uri, null)
                wellKnownOpenIdConfiguration = try(v.registration.open_id_connect_configuration.well_known_open_id_configuration, null)
              }
            }
            login = v.login == null ? null : {
              nameClaimType = try(v.login.name_claim_type, null)
              scopes        = try(v.login.scopes, null)
            }
          }
        } : null
      }
    }
  }
}







