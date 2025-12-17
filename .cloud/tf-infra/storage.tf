resource "azurerm_storage_account" "infra" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "builds" {
  name                  = "build-contexts"
  storage_account_id    = azurerm_storage_account.infra.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "docker_context" {
  name                   = "docker_context.zip"
  storage_account_name   = azurerm_storage_account.infra.name
  storage_container_name = azurerm_storage_container.builds.name
  type                   = "Block"
  source                 = data.archive_file.docker_context.output_path
  content_md5            = data.archive_file.docker_context.output_md5
}

resource "azurerm_role_assignment" "vm_blob_reader" {
  scope                = azurerm_storage_container.builds.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.nexus_vm.principal_id
}
