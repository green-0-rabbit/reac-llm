terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.52.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7.0"
    }
  }

  required_version = ">= 1.1.0"
}