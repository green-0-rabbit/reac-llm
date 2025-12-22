variable "default_realm_name" {
  type        = string
  description = "keycloak default realm name"
}

variable "client_sso" {
  description = "Configuration for the SSO client"
  type = object({
    client_id                    = string
    enabled                      = bool
    direct_access_grants_enabled = bool
    standard_flow_enabled        = bool
    access_type                  = string
    valid_redirect_uris          = list(string)
    login_theme                  = optional(string, "keycloak")
    full_scope_allowed           = bool
  })
}


variable "users" {
  description = "List of users"
  type = list(object({
    tf_id      = string
    username   = string
    enabled    = bool
    email      = string
    first_name = string
    last_name  = string
    attributes = optional(map(string))
    password   = string
    temporary  = bool
  }))
  default = []
}

variable "realm_config" {
  description = "Realm config"
  type = object({
    reset_password_allowed         = optional(bool)
    otp_enabled                    = bool
    edit_username_allowed          = optional(bool)
    login_with_email_allowed       = optional(bool)
    remember_me                    = optional(bool)
    registration_email_as_username = optional(bool)
    verify_email                   = optional(bool)
    access_code_lifespan           = optional(string)
    password_policy                = optional(list(string))
  })
}

variable "realm_roles" {
  description = "List of roles"
  type = list(object({
    name        = string
    description = optional(string)
    attributes = list(object({
      key   = string
      value = string
    }))
  }))
  default = []
}