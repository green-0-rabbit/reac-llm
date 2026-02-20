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
admin_username = "bastionadmin"

devbox_custom_image_id = "/subscriptions/64aff275-5209-47fd-88a0-f127dfab04b8/resourceGroups/sbx-main-rg/providers/Microsoft.Compute/galleries/sbx_devbox_gallery_kag/images/devbox/versions/0.0.1"

# Optional Windows DevBox deployment
enable_windows_devbox               = true
windows_devbox_vm_size              = "Standard_D2s_v3"
windows_devbox_custom_image_id      = "/communityGalleries/sbckag-03a467c4-f8e6-470f-a19a-0b1f72763fd6/images/windevbox/versions/0.0.3"
windows_devbox_enable_wsl_bootstrap = true

private_dns_zone_name = "sbx-kag.io"

vnet_name               = "main-hub"
main_vnet_address_space = ["10.0.0.0/16"]

hub_subnets = {
  MainSubnet = {
    subnet_address_prefix = ["10.0.1.0/24"]
  }

  PrivateEndpointSubnet = {
    subnet_address_prefix = ["10.0.5.0/24"]
  }

  BastionSubnet = {
    subnet_address_prefix = ["10.0.7.0/27"]
    nsg_inbound_rules = {
      "Allow-SSH-Trusted" = {
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = ["0.0.0.0/0"]
        destination_address_prefix = "*"
      }
      "Allow-RDP-From-Bastion" = {
        priority                   = 210
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefixes    = ["0.0.0.0/0"]
        destination_address_prefix = "*"
      }
    }
  }
  # Required for Azure Bastion (Standard or higher)
  AzureBastionSubnet = {
    subnet_address_prefix = ["10.0.3.0/26"]
  }
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
    "ai-hub-backend:23065",
    "ai-hub-frontend:22934",
  ]
}

bunny_dns = {
  acme_email = "contact@humaapi.com"
  zone_name  = "wp.humaapi.com"
}

aca_private_endpoint_ip = "10.1.5.10"

