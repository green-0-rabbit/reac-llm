# locals {
#   nexus_seed_images_script = templatefile(
#     "${path.module}/scripts/seed-images.sh.tmpl",
#     { images_json = jsonencode(var.seed_config.images) }
#   )
# }

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
      nexus_fqdn             = local.nexus_fqdn
      nexus_password         = var.admin_password
      acr_name               = var.acr_name
      dockerhub_username     = var.dockerhub_credentials.username
      dockerhub_password     = var.dockerhub_credentials.password
      seed_config            = var.seed_config
      sync_config            = var.sync_config
      dockerfile_content_b64 = base64encode(var.dockerfile_content)
      docker_context_url     = var.docker_build_context_url
      custom_image_name      = var.custom_image_name
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

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
      bash -lc '
      until [ -f /var/lib/cloud/instance/boot-finished ]; do echo waiting-cloud-init; sleep 5; done
      systemctl enable --now docker || true
      until systemctl is-active --quiet docker; do echo wait-docker; sleep 2; done
      until [ -S /var/run/docker.sock ]; do echo wait-docker-sock; sleep 2; done
      /usr/local/bin/nexus-wait.sh && \
      /usr/local/bin/provision-nexus.sh && \
      /usr/local/bin/build-custom-image.sh ${var.custom_image_name} && \
      /usr/local/bin/provision-acr-sync.sh 2>&1 | tee -a /var/log/provision-acr-sync.log
      '
    EOT
  })

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.nexus
  ]
}

# Seed desired Docker Hub images into Nexus using Managed Run Command.
# Re-runs when seed_config.images changes, without redeploying the VM.
# resource "azurerm_virtual_machine_run_command" "nexus_seed_images" {
#   name               = "nexus-seed-images"
#   location           = var.location
#   virtual_machine_id = azurerm_linux_virtual_machine.nexus.id

#   # Ensure initial Nexus provisioning (container + realms + repo + nginx) is done first
#   depends_on = [azurerm_virtual_machine_extension.nexus_provision]

#   source {
#     script = local.nexus_seed_images_script
#   }
# }



resource "azurerm_role_assignment" "nexus_vm_acr_push" {
  count                = var.enable_managed_identity ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine.nexus.identity[0].principal_id

  lifecycle {
    precondition {
      condition     = var.acr_id != ""
      error_message = "acr_id must be provided when enable_managed_identity is true."
    }
  }
}






