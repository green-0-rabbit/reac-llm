# NOTE: Using Standard SKU because Developer SKU does not support VNet peering (required for Hub-Spoke)
# and has limitations with dedicated subnet/IP configurations.

# resource "azurerm_public_ip" "bastion_pip" {
#   name                = "${var.project}-bastion-pip"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "bastion" {
#   name                = "${var.project}-bastion"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   sku                 = "Standard"

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = module.vnet-spoke1.subnet_ids["AzureBastionSubnet"]
#     public_ip_address_id = azurerm_public_ip.bastion_pip.id
#   }
# }

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.project}-bastion"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Developer"

  #   virtual_network_id = azurerm_virtual_network.main.id
  virtual_network_id = module.vnet-hub.id

  # Ensure the AzureBastionSubnet is created before the Bastion Host
  depends_on = [module.vnet-hub]
}