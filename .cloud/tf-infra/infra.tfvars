project      = "sbx"
location     = "westeurope"
environments = ["dev", "staging", "prod"]


#### acr variables
acr_settings = {
  name                 = "sbxinfraacrkag"
  sku                  = "Premium"
  private_link_enabled = true
}

storage_account_name = "sbxinfrastoragekag"

#### nexus vm variables
admin_username = "nexusadmin"

private_dns_zone_name = "sbx-kag.io"

vnet_name               = "main-hub"
main_vnet_address_space = ["10.0.0.0/16"]

hub_subnets = {
  MainSubnet = {
    subnet_address_prefix = ["10.0.1.0/24"]
  }

  WorkloadSubnet = {
    subnet_address_prefix = ["10.0.4.0/24"]
    nsg_inbound_rules = {
      "Allow-SSH-Trusted" = {
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = ["81.65.88.13"]
        destination_address_prefix = "*"
      }
      "Allow-Bastion-Dev" = {
        priority                   = 150
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["22", "3389"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
      "Allow-Nexus-UI-VNet" = {
        priority                   = 210
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8081"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
    }
  }
  PrivateEndpointSubnet = {
    subnet_address_prefix = ["10.0.5.0/24"]
  }

  BastionSubnet = {
    subnet_address_prefix = ["10.0.7.0/27"]
  }
  # Only needed if Azure Bastion is sku 'Standard' or higher
  # AzureBastionSubnet = {
  #   subnet_address_prefix = ["10.0.3.0/26"]
  # }
}

hub_firewall = {
  sku_name = "AZFW_VNet"
  sku_tier = "Standard"
  # private_ip_address    = "10.0.100.4"
  subnet_address_prefix = ["10.0.14.0/23"]
}

#### Remote acr config for bastion vm to pull images

remote_acr_config = {
  username = "aihubazqsbx"
  fqdn     = "aiportalregistry.azurecr.io"
  images = [
    "ai-hub-backend:21274",
    "ai-hub-frontend:21624",
  ]
}

