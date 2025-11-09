############################
# VM
############################
resource "azurerm_linux_virtual_machine" "nexus" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.nexus.id]

  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password

  os_disk {
    name                 = coalesce(var.osdisk_name, "${var.vm_name}-osdisk")
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_sku
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = "latest"
  }

  # Pass the computed FQDN into cloud-init
  custom_data = base64encode(
    templatefile("${path.module}/cloud-init-nexus.yml", {
      nexus_fqdn     = local.nexus_fqdn
      nexus_password = var.admin_password
    })
  )

  tags = var.tags
}

############################
# Disks
############################

resource "azurerm_managed_disk" "nexus_data" {
  name                 = coalesce(var.datadisk_name, "${var.vm_name}-data")
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}


resource "azurerm_virtual_machine_data_disk_attachment" "nexus" {
  managed_disk_id    = azurerm_managed_disk.nexus_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.nexus.id
  lun                = 0
  caching            = "ReadWrite"
}

############################
# Extensions
############################

resource "azurerm_virtual_machine_extension" "nexus_provision" {
  name                       = "nexus-provisioning"
  virtual_machine_id         = azurerm_linux_virtual_machine.nexus.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  # On laisse le script dans cloud-init: /usr/local/bin/provision-nexus.sh
  protected_settings = jsonencode({
    commandToExecute = "bash -lc 'until [ -f /var/lib/cloud/instance/boot-finished ]; do echo waiting-cloud-init; sleep 5; done; systemctl enable --now docker || true; until systemctl is-active --quiet docker; do echo wait-docker; sleep 2; done; until [ -S /var/run/docker.sock ]; do echo wait-docker-sock; sleep 2; done; /usr/local/bin/nexus-wait.sh && /usr/local/bin/provision-nexus.sh'"
  })

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.nexus
  ]
}






