variable "app_config" {
  type = object({
    name                  = string
    revision_mode         = optional(string, "Single")
    workload_profile_name = optional(string)
  })
  validation {
    condition = var.app_config == null ? true : try(
      contains(["Single", "Multiple"], var.app_config.revision_mode),
      true
    )
    error_message = "revision_mode must be either \"Single\" or \"Multiple\"."
  }
}
variable "container_app_environment_id" { type = string }
variable "environment" { type = string }
variable "location" {
  type        = string
  description = "Azure region for the environment (must be Switzerland North/West)."
  validation {
    condition     = contains(["switzerlandnorth", "switzerlandwest", "westeurope"], var.location)
    error_message = "location must be one of: switzerlandnorth, switzerlandwest."
  }
}
variable "resource_group_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "ingress" {
  type = object({
    allow_insecure_connections = optional(bool)
    external_enabled           = optional(bool)
    target_port                = optional(number)
    transport                  = optional(string)
    traffic_weight = optional(list(object({
      latest_revision = optional(bool)
      percentage      = optional(number)
      label           = optional(string)
    })))
  })
  default = null
}
variable "template" {
  type = object({
    containers = list(object({
      name    = string
      image   = string
      cpu     = optional(number)
      memory  = optional(string)
      command = optional(list(string))
      args    = optional(list(string))
      env = optional(list(object({
        name        = string
        value       = optional(string)
        secret_name = optional(string)
      })))
    }))
    min_replicas = optional(number)
    max_replicas = optional(number)
  })
  validation {
    condition     = var.template != null && length(var.template.containers) > 0
    error_message = "The template object must be provided with at least one container definition."
  }
}

variable "registry_fqdn" {
  type        = string
  description = "FQDN of the container registry (e.g., myregistry.azurecr.io)."
}

variable "acr_id" {
  type        = string
  description = "the name of the acr"
}

variable "kv_id" {
  type        = string
  description = "The ID of the Key Vault to assign 'Key Vault Secrets User' role to the user assigned identity."
}

variable "user_assigned_identity" {
  type = object({
    id           = string
    principal_id = string
  })
  description = "The user assigned identity object to be used by the Container App."
}

variable "secrets" {
  type = list(object({
    name                = string
    value               = optional(string)
    key_vault_secret_id = optional(string)
    identity            = optional(string)
  }))
  default     = []
  description = "List of secrets to be used by the Container App. Can be a value or a Key Vault reference."
}
