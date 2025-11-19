locals {
  acr_login_server = data.azurerm_container_registry.acr.login_server
}




module "container_app_environment" {
  source = "./modules/container_app_environment"

  environment                = var.env
  location                   = var.location
  resource_group_name        = var.resource_group_name
  infrastructure_subnet_id   = data.azurerm_subnet.aca.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  create_log_analytics       = var.create_log_analytics

  workload_profile = {
    name = "wkp_container_app_env"
    workload_profile_type = "Consumption"
  }

  tags                       = var.tags
}

#  Example https://github.com/Azure/terraform-azure-container-apps/blob/v0.4.0/examples/acr/main.tf
# Check this https://github.com/thomast1906/thomasthorntoncloud-examples/tree/master/Azure-Container-App-Terraform/Terraform
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

  user_assigned_identity = {
    id           = azurerm_user_assigned_identity.containerapp.id
    principal_id = azurerm_user_assigned_identity.containerapp.principal_id
  }

  registry_fqdn = local.acr_login_server

  acr_id = data.azurerm_container_registry.acr.id

  template = {
    containers = [
      {
        name   = "busybox"
        image  = "${local.acr_login_server}/library/busybox:latest"
        cpu    = 0.5
        memory = "1Gi",
        args   = ["sleep", "3600"]
      }
    ]
  }
}



