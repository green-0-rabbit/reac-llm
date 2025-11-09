# nexus.<zone> -> VM private IP
resource "azurerm_private_dns_a_record" "nexus" {
  name                = var.dns_record_name
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg
  ttl                 = 30
  records             = [azurerm_network_interface.nexus.private_ip_address]
}



