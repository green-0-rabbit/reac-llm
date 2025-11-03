resource "azurerm_resource_group" "env" {
  for_each = toset(var.environments)

  name     = "${var.project}-${each.value}-rg"
  location = var.location
  tags = {
    project = var.project
    env     = each.value
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project}-main-rg"
  location = var.location
  tags = {
    project = var.project
    env     = "main"
  }
}

