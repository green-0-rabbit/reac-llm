variable "server_url" {
  description = "The client secret for the Keycloak provider"
}

variable "default_realm_name" {
    description = "keycloak default realm name"
}

variable "sso_client_name" {
  type = string
  description = "(optional) describe your variable"
}

variable "user_password" {
  type = string
}