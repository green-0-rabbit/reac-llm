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

variable "vnet_name" {
  description = "The name of the main virtual network."
  type        = string
}

variable "main_vnet_address_space" {
  description = "CIDR blocks for the main virtual network."
  type        = list(string)
}

variable "hub_subnets" {
  description = "Subnets to create inside the main virtual network."
  type = map(object({
    subnet_address_prefix                         = list(string)
    service_endpoints                             = optional(list(string), [])
    private_link_service_network_policies_enabled = optional(bool, true)
    firewall_enabled                              = optional(bool, false)
    delegation = optional(object({
      name = optional(string)
      service_delegation = optional(object({
        name    = optional(string)
        actions = optional(list(string))
      }))
    }))

    nsg_inbound_rules = optional(map(object({
      priority                   = number
      direction                  = optional(string, "Inbound")
      access                     = optional(string, "Allow")
      protocol                   = optional(string, "Tcp")
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      destination_port_ranges    = optional(set(string), [])
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(set(string), [])
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {})

    nsg_outbound_rules = optional(map(object({
      priority                   = number
      direction                  = optional(string, "Outbound")
      access                     = optional(string, "Allow")
      protocol                   = optional(string, "Tcp")
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(set(string), [])
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {})
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

variable "hub_firewall" {
  type = object({
    sku_name              = string
    sku_tier              = string
    private_ip_address    = optional(string)
    subnet_address_prefix = optional(list(string), [])
  })
}
