project               = "sbx"
location              = "westeurope"
environments          = ["dev", "staging", "prod"]
private_dns_zone_name = "sbx-kag.io"

main_vnet_address_space = ["10.0.0.0/16"]

main_vnet_subnets = {
  MainSubnet = {
    address_prefixes = ["10.0.1.0/24"]
  }
  WorkloadSubnet = {
    address_prefixes = ["10.0.4.0/24"]
  }
  AzureBastionSubnet = {
    address_prefixes = ["10.0.3.0/26"]
  }
}