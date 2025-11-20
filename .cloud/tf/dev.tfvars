location            = "eastus"
resource_group_name = "sbx-dev-rg"

#### container apps
create_log_analytics = true

#### nexus vm variables
admin_username = "nexusadmin"
nexus_fqdn     = "nexus-infra.sbx-kag.io"

### VNet and subnet names
acr_name = "sbxinfraacrkag"

workload_subnet_name         = "WorkloadSubnet"
bastion_subnet_name          = "AzureBastionSubnet"
main_vnet_name               = "sbx-main-vnet"
aca_subnet_name              = "ACASubnet"
private_endpoint_subnet_name = "PrivateEndpointSubnet"
main_rg_name                 = "sbx-main-rg"


### Private DNS zone RG (backbone)
private_dns_zone_name = "sbx-kag.io"

private_dns_zone_kv_name      = "privatelink.vaultcore.azure.net"
private_dns_zone_storage_name = "privatelink.blob.core.windows.net"

key_vault_name = "sbx-kv-dev-kag"

storage_account_name = "sbxinfrastsa"

