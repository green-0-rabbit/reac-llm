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

variable "project" {
  type = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "private_dns_zone_name" {
  type        = string
  description = "Private DNS zone name (e.g. sbx.example.com)."
}

variable "env" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "The 'env' variable must be one of: dev, staging, prod."
  }
}

variable "main_vnet_name" {
  type        = string
  description = "Name of the main virtual network (from backbone)."
}

variable "main_rg_name" {
  type        = string
  description = "Name of the resource group containing the main VNet (from backbone)."
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Existing Log Analytics workspace ID to reuse."
  default     = ""
}

variable "create_log_analytics" {
  type        = bool
  description = "Whether to create a new Log Analytics workspace when one is not supplied."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to resources."
  default     = {}
}

variable "current_ip" {
  description = "The current IP address of the user running Terraform, to be whitelisted in Key Vault."
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

# ACR variables
variable "acr_name" {
  type        = string
  description = "Name of the Hub Azure Container Registry."
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault."
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Azure Storage Account."
}

variable "private_dns_zone_kv_name" {
  type        = string
  description = "Private DNS zone name for Key Vault"
}

variable "private_dns_zone_storage_name" {
  type        = string
  description = "Private DNS zone name for Storage Account"
}

variable "private_dns_zone_acr_name" {
  type        = string
  description = "Private DNS zone name for Azure Container Registry"
}

variable "spoke_vnet_name" {
  description = "The name of the spoke virtual network."
  type        = string
}

variable "spoke_vnet_address_space" {
  description = "The address space to be used for the spoke virtual network."
  type        = list(string)
}

variable "hub_vnet_name" {
  description = "The name of the hub virtual network."
  type        = string
}

variable "spoke_vnet_subnets" {
  description = "Subnets to create inside the spoke virtual network."
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

variable "postgres_administrator_login" {
  description = "The Administrator Login for the PostgreSQL Flexible Server."
  type        = string
}

variable "private_dns_zone_postgres_name" {
  type        = string
  description = "Private DNS zone name for PostgreSQL Flexible Server"
}

variable "private_dns_azure_monitor_names" {
  type        = list(string)
  description = "List of Private DNS zone names for Azure Monitor"
}

variable "private_dns_azure_ai_names" {
  type        = list(string)
  description = "List of Private DNS zone names for Azure AI services"
}
