# Container App definition with optional registry integration
resource "azurerm_container_app" "app" {
  name                         = "${local.app_settings.name}-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = local.app_settings.revision_mode
  workload_profile_name        = local.app_settings.workload_profile_name


  dynamic "ingress" {
    for_each = local.effective_ingress == null ? [] : [local.effective_ingress]
    content {
      allow_insecure_connections = lookup(ingress.value, "allow_insecure_connections", false)
      external_enabled           = lookup(ingress.value, "external_enabled", false)
      target_port                = lookup(ingress.value, "target_port", 8080)
      transport                  = lookup(ingress.value, "transport", "auto")

      dynamic "traffic_weight" {
        for_each = {
          for index, weight in try(ingress.value.traffic_weight, local.default_ingress.traffic_weight) : index => weight
        }
        content {
          latest_revision = lookup(traffic_weight.value, "latest_revision", null)
          label           = lookup(traffic_weight.value, "label", null)
          percentage      = lookup(traffic_weight.value, "percentage", 100)
        }
      }
    }
  }

  dynamic "registry" {
    for_each = local.registry_config == null ? [] : [local.registry_config]
    content {
      server               = registry.value.server
      username             = registry.value.username
      password_secret_name = registry.value.secret_name
    }
  }

  dynamic "secret" {
    for_each = local.registry_config != null && try(local.registry_config.password, "") != "" ? [local.registry_config.password] : []
    content {
      name  = local.registry_config.secret_name
      value = secret.value
    }
  }

  template {
    dynamic "container" {
      for_each = {
        for index, container in local.effective_template.containers : index => container
      }
      content {
        name   = container.value.name
        image  = container.value.image
        cpu    = lookup(container.value, "cpu", null)
        memory = lookup(container.value, "memory", null)

        dynamic "env" {
          for_each = {
            for index, env_item in coalesce(try(container.value.env, []), []) : index => env_item
          }
          content {
            name        = env.value.name
            value       = lookup(env.value, "value", null)
            secret_name = lookup(env.value, "secret_name", null)
          }
        }
      }
    }

    min_replicas = try(local.effective_template.min_replicas, null)
    max_replicas = try(local.effective_template.max_replicas, null)
  }

  tags = var.tags
}
