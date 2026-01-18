location            = "westeurope"
resource_group_name = "sbx-aihub-rg"
project             = "sbx-aihub"

#### Remote acr config for bastion vm to pull images

remote_acr_config = {
  username = "aihubazqsbx"
  fqdn     = "aiportalregistry.azurecr.io"
  images = [
    "ai-hub-backend:21274",
    "ai-hub-frontend:21624",
  ]
}

#### container apps
create_log_analytics = true

#### bastion vm variables
admin_username = "bastionadmin"

### VNet and subnet names
acr_name = "sbxinfraacrkag"

main_vnet_name = "sbx-main-vnet"
main_rg_name   = "sbx-main-rg"


### Private DNS zone RG (backbone)
private_dns_zone_name = "sbx-kag.io"

private_dns_zone_kv_name       = "privatelink.vaultcore.azure.net"
private_dns_zone_storage_name  = "privatelink.blob.core.windows.net"
private_dns_zone_acr_name      = "privatelink.azurecr.io"
private_dns_zone_postgres_name = "sbx-kag.postgres.database.azure.com"
private_dns_azure_monitor_names = [
  "privatelink.monitor.azure.com",
  "privatelink.oms.opinsights.azure.com",
  "privatelink.ods.opinsights.azure.com",
  "privatelink.agentsvc.azure-automation.net",
]

postgres_administrator_login = "psqladmin"

key_vault_name = "sbx-aihub-kv-dev-aihub"

storage_account_name = "sbxaihubinfrastsa"

##### Hub vNet variables
hub_vnet_name = "vnet-main-hub"


###### Spoke vNet variables
spoke_vnet_name          = "spoke1"
spoke_vnet_address_space = ["10.1.0.0/16"]
spoke_vnet_subnets = {
  ACASubnet = {
    # firewall_enabled      = true
    subnet_address_prefix = ["10.1.6.0/23"]
    delegation = {
      name = "aca-delegation"
      service_delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    nsg_inbound_rules = {
      "Allow-HTTP-HTTPS" = {
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80", "443"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
      "Allow-ACA-Ports" = {
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "30000-32767"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
      "Deny-Internet-Inbound" = {
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        destination_port_range     = "*"
        source_port_range          = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
      }
    }
  }
  PrivateEndpointSubnet = {
    subnet_address_prefix = ["10.1.5.0/24"]
  }
  ApplicationGatewaySubnet = {
    subnet_address_prefix                         = ["10.1.9.0/24"]
    private_link_service_network_policies_enabled = false
    nsg_inbound_rules = {
      "Allow-GatewayManager" = {
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "65200-65535"
        source_address_prefix      = "GatewayManager"
        destination_address_prefix = "*"
      }
      "Allow-HTTP-HTTPS" = {
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80", "443"]
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
      }
    }
  }
  BastionSubnet = {
    subnet_address_prefix = ["10.0.4.0/27"]
  }
  PostgresSubnet = {
    subnet_address_prefix = ["10.1.8.0/24"]
    delegation = {
      name = "fs-delegation"
      service_delegation = {
        name    = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

