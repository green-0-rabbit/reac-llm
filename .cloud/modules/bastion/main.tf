############################
# VM
############################
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.bastion.id]

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
    templatefile("${path.module}/cloud-init.yml", {
      acr_name                = var.acr_name
      remote_acr_username     = var.remote_acr_config.username
      remote_acr_password     = var.remote_acr_password
      remote_acr_fqdn         = var.remote_acr_config.fqdn
      remote_acr_images       = var.remote_acr_config.images
      sync_remote_acr_acr_b64 = base64encode(file("${path.module}/scripts/sync_remote_acr_acr.sh"))
    })
  )

  tags = var.tags

  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
}

############################
# Disks
############################

resource "azurerm_managed_disk" "bastion_data" {
  name                 = coalesce(var.datadisk_name, "${var.vm_name}-data")
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}


resource "azurerm_virtual_machine_data_disk_attachment" "bastion" {
  managed_disk_id    = azurerm_managed_disk.bastion_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.bastion.id
  lun                = 0
  caching            = "ReadWrite"
}

############################
# Extensions
############################

resource "azurerm_virtual_machine_extension" "bastion_provision" {
  name                       = "bastion-provisioning"
  virtual_machine_id         = azurerm_linux_virtual_machine.bastion.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
      bash -lc '
      until [ -f /var/lib/cloud/instance/boot-finished ]; do echo waiting-cloud-init; sleep 5; done
      systemctl enable --now docker || true
      until systemctl is-active --quiet docker; do echo wait-docker; sleep 2; done
      until [ -S /var/run/docker.sock ]; do echo wait-docker-sock; sleep 2; done
      /usr/local/bin/sync_remote_acr_acr.sh \
      ${var.remote_acr_config.username} \
      ${var.remote_acr_password} \
      ${var.remote_acr_config.fqdn}
      '
    EOT
  })

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.bastion
  ]
}

resource "azurerm_role_assignment" "bastion_vm_acr_push" {
  count                = var.enable_managed_identity ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine.bastion.identity[0].principal_id

  lifecycle {
    precondition {
      condition     = var.acr_id != ""
      error_message = "acr_id must be provided when enable_managed_identity is true."
    }
  }
}






