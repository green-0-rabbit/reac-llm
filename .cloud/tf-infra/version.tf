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
      version = "~> 2.7.0"
    }
    bunnynet = {
      source  = "BunnyWay/bunnynet"
      version = "0.13.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.1.0"
}