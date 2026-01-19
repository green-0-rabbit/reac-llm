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
    roles      = optional(list(string), [])
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
    ssl_required                   = optional(string)
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

variable "saml_clients" {
  description = "List of SAML clients"
  type = list(object({
    client_id                           = string
    name                                = optional(string)
    sign_documents                      = optional(bool, true)
    sign_assertions                     = optional(bool, true)
    encrypt_assertions                  = optional(bool, false)
    client_signature_required           = optional(bool, true)
    force_post_binding                  = optional(bool, false)
    front_channel_logout                = optional(bool, true)
    name_id_format                      = optional(string, "email")
    valid_redirect_uris                 = list(string)
    assertion_consumer_post_url         = string
    assertion_consumer_redirect_url     = string
    logout_service_post_binding_url     = string
    logout_service_redirect_binding_url = string
    signing_certificate                 = optional(string)
    signing_private_key                 = optional(string)
    signature_algorithm                 = optional(string, "RSA_SHA256")
    protocol_mappers = optional(list(object({
      name                       = string
      user_property              = string
      saml_attribute_name        = string
      saml_attribute_name_format = optional(string, "Basic")
    })), [])
  }))
  default = []
}


variable "realm_private_key" {
  type        = string
  description = "Private key for the realm"
  default     = null
}

variable "realm_certificate" {
  type        = string
  description = "Certificate for the realm"
  default     = null
}
