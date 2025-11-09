locals {
  app_settings = merge({
    revision_mode         = "Single"
    workload_profile_name = null
  }, var.app_config)


  registry_config = var.registry != null ? merge({
    secret_name = "registry-password"
  }, var.registry) : null

  default_ingress = {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = 8080
    transport                  = "auto"
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }


  effective_template = var.template
  effective_ingress  = var.ingress != null ? var.ingress : local.default_ingress
}
