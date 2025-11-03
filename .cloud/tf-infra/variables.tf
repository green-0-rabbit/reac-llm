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
    address_prefixes = list(string)
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


