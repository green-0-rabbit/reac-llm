module "ai_foundry" {
  source = "../../modules/aifoundry"

  application_id                = "aifoundry-${var.project}"
  environment                   = var.env
  location                      = var.location
  target_rg                     = azurerm_resource_group.rg.name
  public_network_access_enabled = true
  kind                          = "AIServices"
  sku_name                      = "S0"
  networking = {
    subnet_id                    = module.vnet-spoke1.subnet_ids["PrivateEndpointSubnet"]
    static_ip_address_allocation = false
  }
  dns = {
    register_pe_to_dns = true
    ai_foundry_dns_ids = values(data.azurerm_private_dns_zone.ai_services)[*].id
  }
  models = {
    "gpt-4.1" = {
      version  = "2025-04-14"
      sku      = "GlobalStandard"
      capacity = 50
    }
  }
}
