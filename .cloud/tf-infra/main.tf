module "nexus_vm" {
  source = "../modules/nexus_vm"

  # Placement
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  subnet_id           = module.vnet-hub.subnet_ids["WorkloadSubnet"]

  # VM basics
  vm_name        = "vm-nexus-${var.env}"
  admin_username = var.admin_username
  admin_password = var.admin_password

  private_dns_zone_name = azurerm_private_dns_zone.sbx_zone.name
  private_dns_zone_rg   = azurerm_resource_group.main.name
  dns_record_name       = "nexus-${var.env}"

  # ACR / identity wiring
  enable_managed_identity = true
  acr_id                  = module.acr.id
  acr_name                = module.acr.name

  # Optional Docker Hub auth (to avoid rate limits)
  dockerhub_credentials = var.dockerhub_credentials

  # Seeding and sync
  seed_config = var.seed_config
  sync_config = var.sync_config

  dockerfile_content       = file("${path.module}/../docker/Dockerfile")
  docker_build_context_url = azurerm_storage_blob.docker_context.url
  custom_image_name        = "local/todo-app-api:latest"
}

module "vnet-hub" {
  source = "../modules/vnet"

  # By default, this module will create a resource group, proivde the name here
  # to use an existing resource group, specify the existing resource group name,
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_name           = var.vnet_name
  is_hub              = true

  # Provide valid VNet Address space for spoke virtual network.  
  vnet_address_space = var.main_vnet_address_space

  # Hub network details to create peering and other setup

  private_dns_zone_names = concat(
    [
      azurerm_private_dns_zone.sbx_zone.name,
      azurerm_private_dns_zone.keyvault.name,
      azurerm_private_dns_zone.blob.name,
      azurerm_private_dns_zone.postgres.name,
      module.acr.private_dns_zone_name,
    ],
    values(azurerm_private_dns_zone.ampls)[*].name
  )


  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # Route_table and NSG association to be added automatically for all subnets listed here.
  # subnet name will be set as per Azure naming convention by defaut. expected value here is: <App or project name>
  subnets = var.hub_subnets

  # firewall = {
  #   sku_name              = var.hub_firewall.sku_name
  #   sku_tier              = var.hub_firewall.sku_tier
  #   subnet_address_prefix = var.hub_firewall.subnet_address_prefix
  #   private_ip_address    = var.hub_firewall.private_ip_address
  #   # (Optional) specify the application rules for Azure Firewall
  #   firewall_application_rules = [
  #     {
  #       name             = "microsoft"
  #       action           = "Allow"
  #       source_addresses = ["10.0.0.0/8"]
  #       target_fqdns     = ["*.microsoft.com"]
  #       protocol = {
  #         type = "Http"
  #         port = "80"
  #       }
  #     },
  #   ]
  #   # (Optional) specify the Network rules for Azure Firewall
  #   firewall_network_rules = [
  #     {
  #       name                  = "ntp"
  #       action                = "Allow"
  #       source_addresses      = ["10.0.0.0/8"]
  #       destination_ports     = ["123"]
  #       destination_addresses = ["*"]
  #       protocols             = ["UDP"]
  #     },
  #   ]
  #   # (Optional) specify the NAT rules for Azure Firewall
  #   # Destination address must be Firewall public IP
  #   # `fw-public` is a variable value and automatically pick the firewall public IP from module.
  #   firewall_nat_rules = [
  #     {
  #       name                  = "testrule"
  #       action                = "Dnat"
  #       source_addresses      = ["10.0.0.0/8"]
  #       destination_ports     = ["53", ]
  #       destination_addresses = ["fw-public"]
  #       translated_port       = 53
  #       translated_address    = "8.8.8.8"
  #       protocols             = ["TCP", "UDP", ]
  #     },
  #   ]
  # }


  tags = {
    project-name = "sbx-kag"
  }
}



