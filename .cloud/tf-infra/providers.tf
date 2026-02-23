provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "bunnynet" {
  api_key = var.bunnynet_api_key
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
