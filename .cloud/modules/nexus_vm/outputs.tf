output "nexus_private_ip" {
  value       = azurerm_network_interface.nexus.private_ip_address
  description = "Private IP of the Nexus VM."
}

output "nexus_vm_id" {
  value       = azurerm_linux_virtual_machine.nexus.id
  description = "Resource ID of the Nexus VM."
}

output "nexus_fqdn" {
  value       = local.nexus_fqdn
  description = "FQDN used by the registry (must resolve privately)."
}

output "principal_id" {
  value       = var.enable_managed_identity ? azurerm_linux_virtual_machine.nexus.identity[0].principal_id : null
  description = "Principal ID of the System Assigned Identity of the VM."
}