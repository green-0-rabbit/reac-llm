output "private_ip" {
  value       = azurerm_network_interface.nic.private_ip_address
  description = "Private IP of the DevBox VM."
}

output "vm_id" {
  value       = azurerm_linux_virtual_machine.devbox.id
  description = "Resource ID of the DevBox VM."
}

output "principal_id" {
  value = var.enable_managed_identity ? azurerm_linux_virtual_machine.devbox.identity[0].principal_id : null
}

output "public_ip" {
  value = var.enable_public_ip ? azurerm_public_ip.pip[0].ip_address : null
}

output "bastion_name" {
  value       = var.enable_bastion_host ? azurerm_bastion_host.devbox_bastion[0].name : null
  description = "Name of the DevBox Bastion host."
}

output "bastion_public_ip" {
  value       = var.enable_bastion_host ? azurerm_public_ip.devbox_bastion_pip[0].ip_address : null
  description = "Public IP of the DevBox Bastion host."
}
