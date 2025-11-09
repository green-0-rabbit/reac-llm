location            = "westeurope"
resource_group_name = "sbx-dev-rg"

#### container apps
create_log_analytics = true
internal_only        = true

#### nexus vm variables
admin_username = "nexusadmin"
nexus_fqdn     = "nexus-infra.sbx-kag.io"

workload_subnet_name = "WorkloadSubnet"
bastion_subnet_name  = "AzureBastionSubnet"
main_vnet_name       = "sbx-main-vnet"
aca_subnet_name      = "ACASubnet"
main_rg_name         = "sbx-main-rg"


### Private DNS zone RG (backbone)
private_dns_zone_name = "sbx-kag.io"

