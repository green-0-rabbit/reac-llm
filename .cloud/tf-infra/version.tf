terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.50.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
  }

  required_version = ">= 1.1.0"
}