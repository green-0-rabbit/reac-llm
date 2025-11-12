# resource "azurerm_bastion_host" "bastion" {
#   name                = "${var.project}-bastion"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   sku                 = "Standard"

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.main["AzureBastionSubnet"].id
#     public_ip_address_id = azurerm_public_ip.bastion.id
#   }

#   copy_paste_enabled     = true
#   file_copy_enabled      = true
#   tunneling_enabled      = true # needed for az network bastion tunnel
#   shareable_link_enabled = false
# }

# resource "azurerm_public_ip" "bastion" {
#   name                = "${var.project}-bastion-pip"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }