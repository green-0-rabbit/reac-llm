variable "app_config" {
  type = object({
    name                  = optional(string, "default-app")
    revision_mode         = optional(string, "Single")
    workload_profile_name = optional(string, "Consumption")
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
    condition     = contains(["switzerlandnorth", "switzerlandwest", "eastus", "westeurope"], var.location)
    error_message = "location must be one of: switzerlandnorth, switzerlandwest, eastus, westeurope."
  }
}
variable "resource_group_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "ingress" {
  type = object({
    allow_insecure_connections = optional(bool, false)
    external_enabled           = optional(bool, false)
    target_port                = optional(number, 8080)
    transport                  = optional(string, "auto")
    traffic_weight = optional(list(object({
      latest_revision = optional(bool, true)
      percentage      = optional(number, 100)
      label           = optional(string)
    })), [{
      latest_revision = true
      percentage      = 100
    }])
  })
  default = null
}

variable "custom_domain" {
  description = "Custom domain configuration for the container app"
  type = object({
    name                     = string
    certificate_id           = string
    certificate_binding_type = string
  })
  default = null
}
variable "template" {
  type = object({
    containers = list(object({
      name    = string
      image   = string
      cpu     = optional(number, 0.25)
      memory  = optional(string, "0.5Gi")
      command = optional(list(string))
      args    = optional(list(string))
      env = optional(list(object({
        name        = string
        value       = optional(string)
        secret_name = optional(string)
      })), [])
    }))
    min_replicas = optional(number, 0)
    max_replicas = optional(number, 10)
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
  default     = null
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
