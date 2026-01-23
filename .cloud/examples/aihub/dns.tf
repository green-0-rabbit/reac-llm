resource "azurerm_private_dns_a_record" "aca_apex" {
  name                = "@"
  zone_name           = data.azurerm_private_dns_zone.sbx.name
  resource_group_name = data.azurerm_private_dns_zone.sbx.resource_group_name
  ttl                 = 300
  records             = [module.container_app_environment.static_ip_address]
}

resource "azurerm_private_dns_a_record" "aca_wildcard" {
  name                = "*"
  zone_name           = data.azurerm_private_dns_zone.sbx.name
  resource_group_name = data.azurerm_private_dns_zone.sbx.resource_group_name
  ttl                 = 300
  records             = [module.container_app_environment.static_ip_address]
}
