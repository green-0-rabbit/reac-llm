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
  count                = var.user_assigned_identity != null ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.user_assigned_identity.principal_id
}

resource "azurerm_role_assignment" "acr_pull_system" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.app.identity[0].principal_id
}






