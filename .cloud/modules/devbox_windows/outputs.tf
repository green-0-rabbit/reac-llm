output "private_ip" {
  value       = azurerm_network_interface.nic.private_ip_address
  description = "Private IP of the Windows DevBox VM."
}

output "vm_id" {
  value       = azurerm_windows_virtual_machine.devbox.id
  description = "Resource ID of the Windows DevBox VM."
}

output "principal_id" {
  value = var.enable_managed_identity ? azurerm_windows_virtual_machine.devbox.identity[0].principal_id : null
}

output "public_ip" {
  value = var.enable_public_ip ? azurerm_public_ip.pip[0].ip_address : null
}

output "bastion_name" {
  value       = var.enable_bastion_host ? azurerm_bastion_host.devbox_bastion[0].name : null
  description = "Name of the Windows DevBox Bastion host."
}

output "bastion_public_ip" {
  value       = null
  description = "Developer Bastion has no public IP."
}
