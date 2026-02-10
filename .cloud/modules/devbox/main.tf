############################
# VM
############################
resource "azurerm_linux_virtual_machine" "devbox" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password

  os_disk {
    name                 = coalesce(var.osdisk_name, "${var.vm_name}-osdisk")
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_sku
  }

  source_image_id = var.custom_image_id

  dynamic "source_image_reference" {
    for_each = var.custom_image_id == null ? [1] : []
    content {
      publisher = var.image_publisher
      offer     = var.image_offer
      sku       = var.image_sku
      version   = "latest"
    }
  }

  # Skip cloud-init when using a custom image
  custom_data = var.custom_image_id == null ? base64encode(
    templatefile("${path.module}/cloud-init.yml", {
      env_vars = var.env_vars
    })
  ) : null

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

resource "azurerm_managed_disk" "devbox_data" {
  name                 = coalesce(var.datadisk_name, "${var.vm_name}-data")
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_sku
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}


resource "azurerm_virtual_machine_data_disk_attachment" "devbox" {
  managed_disk_id    = azurerm_managed_disk.devbox_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.devbox.id
  lun                = 0
  caching            = "ReadWrite"
}

############################
# Extensions
############################

resource "azurerm_virtual_machine_extension" "provision" {
  count = var.custom_image_id == null ? 1 : 0
  name                       = "devbox-provisioning"
  virtual_machine_id         = azurerm_linux_virtual_machine.devbox.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
      bash -lc '
      until [ -f /var/lib/cloud/instance/boot-finished ]; do echo waiting-cloud-init; sleep 5; done
      echo "DevBox Provisioning Complete" > /var/log/devbox_provisioned.log
      '
    EOT
  })

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.devbox
  ]
}
