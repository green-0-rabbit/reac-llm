output "private_dns_zone_name" {
  value       = azurerm_private_dns_zone.sbx_zone.name
  description = "Backbone private zone (e.g. sbx.example.com)."
}

output "private_dns_zone_rg" {
  value       = azurerm_resource_group.main.name
  description = "RG hosting the private DNS zone."
}

### Bastion Outputs

output "bastion_public_ip" {
  value = module.bastion_vm.vm_public_ip
}

output "bastion_private_ip" {
  value = module.bastion_vm.bastion_private_ip
}


