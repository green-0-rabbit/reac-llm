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
    ], values(data.azurerm_private_dns_zone.monitor)[*].name
    , values(data.azurerm_private_dns_zone.ai_services)[*].name
  )


  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # Route_table and NSG association to be added automatically for all subnets listed here.
  subnets = var.spoke_vnet_subnets

  tags = {
    project-name = "sbx-${var.env}-kag"
  }
}
