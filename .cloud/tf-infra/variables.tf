variable "project" {
  description = "Project name for tagging resources."
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID."
  type        = string
}

variable "location" {
  description = "Azure region for deployed resources."
  type        = string
}

variable "environments" {
  description = "List of environments to create."
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}


variable "main_vnet_address_space" {
  description = "CIDR blocks for the main virtual network."
  type        = list(string)
}

variable "main_vnet_subnets" {
  description = "Subnets to create inside the main virtual network."
  type = map(object({
    address_prefix = string
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
}

variable "env" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)."
  validation {
    condition     = contains(["dev", "staging", "prod", "infra"], var.env)
    error_message = "The 'env' variable must be one of: dev, staging, prod."
  }
}

variable "private_dns_zone_name" {
  type        = string
  description = "Private DNS zone name (e.g. sbx.example.com)."
}

variable "trusted_source_prefixes" {
  description = "List of trusted source IP prefixes (CIDRs) allowed to access ACA."
  type        = list(string)
  default     = []
}

variable "firewall_ip_address" {
  description = "IP address of the Azure Firewall or proxy for egress traffic."
  type        = string
}

## Nexus VM Module Variables
variable "admin_username" {
  type    = string
  default = "azureuser"
}

# Nexus VM Admin Password - Defined at the Gitlab level
variable "admin_password" {
  type      = string
  sensitive = true
}


variable "acr_settings" {
  description = "Azure Container Registry configuration."
  type = object({
    name                 = string
    sku                  = optional(string, "Premium")
    private_link_enabled = optional(bool, true)
  })
}

variable "dockerhub_credentials" {
  type = object({
    username = string
    password = string
  })
  default = {
    username = ""
    password = ""
  }
  sensitive = true
}

variable "seed_config" {
  type = object({
    images      = list(string)
    batch_size  = number
    timer_every = string
  })
  default = {
    images      = []
    batch_size  = 1
    timer_every = "2min"
  }
}

variable "sync_config" {
  type = object({
    enable      = bool
    timer_every = string
  })
  default = {
    enable      = true
    timer_every = "2min"
  }
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Azure Storage Account."
}



