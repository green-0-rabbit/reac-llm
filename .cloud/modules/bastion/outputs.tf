output "bastion_private_ip" {
  value       = azurerm_network_interface.bastion.private_ip_address
  description = "Private IP of the Bastion VM."
}

output "bastion_vm_id" {
  value       = azurerm_linux_virtual_machine.bastion.id
  description = "Resource ID of the Bastion VM."
}

output "principal_id" {
  value = var.enable_managed_identity ? azurerm_linux_virtual_machine.bastion.identity[0].principal_id : null
}

output "vm_public_ip" {
  value = var.enable_public_ip ? azurerm_public_ip.bastion_pip[0].ip_address : null
}
