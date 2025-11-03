# --- Look up the existing workload subnet (from backbone) ---
data "azurerm_subnet" "workload" {
  name                 = var.workload_subnet_name # e.g. "snet-work"
  virtual_network_name = var.main_vnet_name       # e.g. "sbx-main-vnet"
  resource_group_name  = var.main_rg_name         # e.g. "sbx-main-rg" (backbone RG)
}

data "azurerm_subnet" "bastion" {
  name                 = var.bastion_subnet_name
  virtual_network_name = var.main_vnet_name
  resource_group_name  = var.main_rg_name
}


module "nexus_vm" {
  source = "./modules/nexus_vm"

  # Placement
  resource_group_name   = var.resource_group_name
  location              = var.location # e.g. "westeurope"
  subnet_id             = data.azurerm_subnet.workload.id
  bastion_subnet_prefix = data.azurerm_subnet.bastion.address_prefix

  # VM basics
  vm_name        = "vm-nexus-${var.env}"
  admin_username = var.admin_username
  admin_password = var.admin_password

  # Private DNS (provided by backbone)
  private_dns_zone_name = var.private_dns_zone_name # e.g. "sbx.example.com"
  private_dns_zone_rg   = var.main_rg_name          # e.g. "sbx-main-rg" (zone holder RG)
  dns_record_name       = "nexus-${var.env}"        # e.g. "nexus-dev"


  # Network access
  # allowed_cidrs    = local.https_cidrs                 # HTTPS(443) for registry (ACA subnets)
  ui_allowed_cidrs = var.ui_allowed_cidrs # 8081 for admin/Bastion IPs

}

