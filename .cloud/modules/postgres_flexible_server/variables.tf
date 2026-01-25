variable "resource_group_name" {
  description = "The name of the resource group in which to create the PostgreSQL Server."
  type        = string
}

variable "location" {
  description = "The location/region where the PostgreSQL Server should be created."
  type        = string
}

variable "server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  type        = string
}

variable "sku_name" {
  description = "The SKU Name for the PostgreSQL Flexible Server. The name of the SKU, follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D4s_v3, MO_Standard_E4s_v3)."
  type        = string
  nullable    = false
}

variable "storage_mb" {
  description = "The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33554432."
  type        = number
  nullable    = false

  validation {
    condition     = contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33554432], var.storage_mb)
    error_message = "Possible values: 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33554432"
  }
}

variable "storage_tier" {
  description = "The name of storage performance tier for IOPS of the PostgreSQL Flexible Server. Possible values are P4, P6, P10, P15, P20, P30, P40, P50, P60, P70, P80."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["P4", "P6", "P10", "P15", "P20", "P30", "P40", "P50", "P60", "P70", "P80"], var.storage_tier)
    error_message = "Possible values: P4, P6, P10, P15, P20, P30, P40, P50, P60, P70, P80"
  }
}

variable "postgres_version" {
  description = "The version of PostgreSQL to use."
  type        = string
  default     = "16"
}

variable "administrator_login" {
  description = "The Administrator Login for the PostgreSQL Flexible Server."
  type        = string
  default     = null
}

variable "administrator_password" {
  description = "The Password associated with the administrator_login for the PostgreSQL Flexible Server."
  type        = string
  default     = null
  sensitive   = true
}

variable "backup_retention_days" {
  description = "The backup retention days for the PostgreSQL Flexible Server."
  type        = number
  default     = 7
}

variable "delegated_subnet_id" {
  description = "The ID of the virtual network subnet to create the PostgreSQL Flexible Server. The subnet must be delegated to Microsoft.DBforPostgreSQL/flexibleServers."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone to create the PostgreSQL Flexible Server. Required if delegated_subnet_id is set."
  type        = string
  default     = null
}

variable "zone" {
  description = "The availability zone for the PostgreSQL Flexible Server."
  type        = string
  default     = "1"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "database_name" {
  description = "The name of the default database to create."
  type        = string
  default     = null
}

variable "charset" {
  description = "The charset for the default database."
  type        = string
  default     = "UTF8"
}

variable "collation" {
  description = "The collation for the default database."
  type        = string
  default     = "en_US.utf8"
}

variable "public_network_access_enabled" {
  description = "Whether or not public network access is allowed for this server."
  type        = bool
  default     = false
}

variable "authentication" {
  description = "Authentication configuration for the PostgreSQL Flexible Server"
  type = object({
    active_directory_auth_enabled = optional(bool)
    password_auth_enabled         = optional(bool)
    tenant_id                     = optional(string)
  })
  default = null
}

