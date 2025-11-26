resource "azurerm_resource_group" "main" {
  name     = "${var.project}-main-rg"
  location = var.location
  tags = {
    project = var.project
    env     = "main"
  }
}