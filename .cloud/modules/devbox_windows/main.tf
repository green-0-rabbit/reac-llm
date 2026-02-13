############################
# VM
############################
resource "azurerm_windows_virtual_machine" "devbox" {
  name                = var.vm_name
  computer_name       = substr(var.vm_name, 0, 15)
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_username = var.admin_username
  admin_password = var.admin_password

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

  automatic_updates_enabled = true
  patch_mode                = "AutomaticByOS"

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
  virtual_machine_id = azurerm_windows_virtual_machine.devbox.id
  lun                = 0
  caching            = "ReadWrite"
}

############################
# Extensions
############################

resource "azurerm_virtual_machine_extension" "wsl_bootstrap" {
  count                      = var.enable_wsl_bootstrap ? 1 : 0
  name                       = "wsl-bootstrap"
  virtual_machine_id         = azurerm_windows_virtual_machine.devbox.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = "powershell -NoProfile -ExecutionPolicy Bypass -Command \"[IO.File]::WriteAllBytes('C:\\bstrap.ps1',[Convert]::FromBase64String('${base64encode(file("${path.module}/scripts/bootstrap-wsl.ps1"))}'));& 'C:\\bstrap.ps1'\""
  })

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.devbox
  ]
}
