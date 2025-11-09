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
variable "location" { type = string }
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
      name   = string
      image  = string
      cpu    = optional(number)
      memory = optional(string)
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
