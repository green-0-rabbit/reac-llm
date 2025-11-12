project      = "sbx"
location     = "westeurope"
environments = ["dev", "staging", "prod"]


#### acr variables
acr_settings = {
  name                 = "sbxinfraacrkag"
  sku                  = "Premium"
  private_link_enabled = true
}

#### nexus vm variables
admin_username = "nexusadmin"

private_dns_zone_name = "sbx-kag.io"

main_vnet_address_space = ["10.0.0.0/16"]

main_vnet_subnets = {
  MainSubnet = {
    address_prefix = "10.0.1.0/24"
  }
  WorkloadSubnet = {
    address_prefix = "10.0.4.0/24"
  }
  # AzureBastionSubnet = {
  #   address_prefix = "10.0.3.0/26"
  # }
  ACASubnet = {
    address_prefix = "10.0.6.0/27"
    delegation = {
      name = "aca-delegation"
      service_delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    } 
  }
}

seed_config = {
  images = [
    "library/busybox:latest",
    "node:alpine3.22",
  ]
  batch_size  = 1
  timer_every = "2min"
}

sync_config = {
  enable      = true
  timer_every = "2min"
}