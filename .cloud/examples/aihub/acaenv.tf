module "container_app_environment" {
  source                             = "../../modules/container_app_environment"
  name                               = "sbx-aihubacaenv-${var.env}"
  env                                = var.env
  location                           = var.location
  resource_group_name                = azurerm_resource_group.rg.name
  infrastructure_subnet_id           = module.vnet-spoke1.subnet_ids["ACASubnet"]
  infrastructure_resource_group_name = "aca-private-${var.env}-rg"
  # logs_destination              = "azure-monitor"
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this[0].id


  # @see https://learn.microsoft.com/en-us/azure/container-apps/workload-profiles-overview
  workload_profile = {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  certificate_config = {
    name                    = "wildcard-cert"
    certificate_blob_base64 = data.terraform_remote_state.infra.outputs.acme_certificate_p12
    certificate_password    = try(data.terraform_remote_state.infra.outputs.acme_certificate_p12_password, "")
  }


  tags = var.tags
}
