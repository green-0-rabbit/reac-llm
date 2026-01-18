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
    certificate_id           = optional(string)
    certificate_binding_type = optional(string)
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
  default = null
}

variable "create_acr_role_assignment" {
  type        = bool
  description = "Whether to create the AcrPull role assignment for the User Assigned Identity."
  default     = true
}

variable "auth" {
  description = "Authentication configuration for the Container App."
  type = object({
    identity_providers = optional(object({
      azure_active_directory = optional(object({
        registration = object({
          client_id                  = string
          client_secret_setting_name = optional(string)
        })
        tenant_id = optional(string)
      }))
      custom_open_id_connect_providers = optional(map(object({
        enabled = optional(bool, true)
        registration = object({
          client_id = string
          client_credential = optional(object({
            method                     = optional(string)
            client_secret_setting_name = optional(string)
          }))
          open_id_connect_configuration = optional(object({
            authorization_endpoint           = optional(string)
            token_endpoint                   = optional(string)
            issuer                           = optional(string)
            certification_uri                = optional(string)
            well_known_open_id_configuration = optional(string)
          }))
        })
        login = optional(object({
          name_claim_type = optional(string)
          scopes          = optional(list(string))
        }))
      })))
    }))
    global_validation = optional(object({
      unauthenticated_client_action = optional(string, "RedirectToLoginPage")
      excluded_paths                = optional(list(string), [])
    }))
  })
  default = null
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
