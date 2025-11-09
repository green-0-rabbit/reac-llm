module "container_app_environment" {
  source = "./modules/container_app_environment"

  environment                = var.env
  location                   = var.location
  resource_group_name        = var.resource_group_name
  infrastructure_subnet_id   = data.azurerm_subnet.aca.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  create_log_analytics       = var.create_log_analytics
  internal_only              = var.internal_only
  tags                       = var.tags
}

module "busybox_app" {
  source = "./modules/container_app"

  app_config = {
    name          = "busybox"
    revision_mode = "Single"
  }
  environment                  = var.env
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = module.container_app_environment.id
  registry = {
    server      = var.nexus_fqdn
    username    = var.admin_username
    password    = var.admin_password
    secret_name = "nexus-registry-secret"
  }

  template = {
    containers = [
      {
        name   = "busybox"
        image  = "${var.nexus_fqdn}/docker-hosted/busybox:latest"
        cpu    = 0.5
        memory = "1Gi"
      }
    ]
  }
}

