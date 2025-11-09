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

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "private_dns_zone_name" {
  type        = string
  description = "Private DNS zone name (e.g. sbx.example.com)."
}

variable "ui_allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to reach Nexus UI (8081); typically Bastion and admin IPs."
}

variable "env" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "The 'env' variable must be one of: dev, staging, prod."
  }
}

variable "workload_subnet_name" {
  type        = string
  description = "Name of the workload subnet where Nexus VM will be deployed."
}

variable "bastion_subnet_name" {
  type        = string
  description = "Name of the bastion subnet."
}

variable "main_vnet_name" {
  type        = string
  description = "Name of the main virtual network (from backbone)."
}

variable "aca_subnet_name" {
  type        = string
  description = "Name of the ACA subnet."
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

variable "internal_only" {
  type        = bool
  description = "Sets the Container Apps environment to use an internal load balancer."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to resources."
  default     = {}
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

variable "nexus_fqdn" {
  type        = string
  description = "Fully Qualified Domain Name for the Nexus server (e.g., nexus.sbx-kag.io)."
}