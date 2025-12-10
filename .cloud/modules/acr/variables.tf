variable "acr_name" {
  description = "ACR name (globally unique, 5-50 alphanumeric)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will host the ACR"
  type        = string
}

variable "location" {
  description = "Azure location, e.g. westeurope"
  type        = string
}

variable "sku" {
  description = "ACR SKU (Premium required if a Private Endpoint is attached later)"
  type        = string
  default     = "Premium"
}

variable "tags" {
  description = "Tags to apply to ACR and DNS resources"
  type        = map(string)
  default     = {}
}

# --- Private DNS zone for ACR Private Link ---

variable "create_private_link_dns_zone" {
  description = "Create the privatelink.azurecr.io Private DNS zone"
  type        = bool
  default     = true
}

variable "vnet_ids" {
  description = "List of VNet IDs to link to the privatelink.azurecr.io zone"
  type        = list(string)
  default     = []
}

variable "dns_link_name_prefix" {
  description = "Prefix used for DNS VNet link names"
  type        = string
  default     = "link"
}

variable "public_access_enabled" {
  type        = bool
  description = "Enable public network access for the ACR"
  default     = false
}
