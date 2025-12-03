variable "env" { type = string }

variable "location" {
  type        = string
  description = "Azure region for the environment (must be Switzerland North/West)."
  validation {
    condition     = contains(["switzerlandnorth", "switzerlandwest", "eastus", "westeurope"], var.location)
    error_message = "location must be one of: switzerlandnorth, switzerlandwest, eastus, westeurope."
  }
}

variable "resource_group_name" { type = string }
variable "infrastructure_subnet_id" { type = string }
variable "log_analytics_workspace_id" {
  type = string
}
variable "lb_internal_only" {
  type    = bool
  default = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Public network access for the Container Apps environment."
  default     = false
}

variable "workload_profile" {
  type = object({
    name                  = string
    workload_profile_type = string
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  })
  validation {
    condition     = contains(["Consumption", "D4", "D8", "D16", "D32", "E4", "E8", "E16", "E32"], var.workload_profile.workload_profile_type)
    error_message = "workload_profile.workload_profile_type must be one of: Consumption, D4, D8, D16, D32, E4, E8, E16, E32."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "certificate_config" {
  description = "Configuration for the Container App Environment Certificate"
  type = object({
    name                    = string
    certificate_blob_base64 = string
    certificate_password    = optional(string, "")
  })
  default = null
}
