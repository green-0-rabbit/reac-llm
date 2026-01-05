output "id" {
  value = azurerm_application_gateway.agw.id
}

output "public_ip" {
  value = one(azurerm_public_ip.pip[*].ip_address)
}
