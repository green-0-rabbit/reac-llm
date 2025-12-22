module "local_keycloak" {
  source = "../../../modules/keycloak"

  realm_config = {
    otp_enabled                    = true
    login_with_email_allowed       = true
    registration_email_as_username = true
    verify_email                   = false
  }
  default_realm_name = var.default_realm_name

  realm_roles = [
    {
      name = "techlead"
      attributes = [
        {
          key   = "api:access"
          value = "WRITE"
        },
        {
          key   = "api:user-management"
          value = "WRITE"
        },
        {
          key   = "api:billing"
          value = "WRITE"
        },

      ]
    },
    {
      name = "developer"
      attributes = [
        {
          key   = "api:access"
          value = "READ"
        },
        {
          key   = "api:user-management"
          value = "READ"
        },
        {
          key   = "api:billing"
          value = "READ"
        },
      ]
    },

  ]
  client_sso = {
    client_id                    = var.sso_client_name
    enabled                      = true
    direct_access_grants_enabled = true
    standard_flow_enabled        = true
    access_type                  = "CONFIDENTIAL"
    root_url                     = "http://localhost:3002/"
    base_url                     = "http://localhost:3002/"
    valid_redirect_uris          = ["http://localhost:3002/*"]
    full_scope_allowed           = false
  }

  users = [
    {
      tf_id      = "47550efc-7385-402b-9511-a0a522e55baf"
      username   = "test@domain.com"
      enabled    = true
      email      = "test@domain.com"
      first_name = "Test"
      last_name  = "User"
      attributes = {
        foo        = "bar"
        multivalue = "value1##value2"
      }
      password  = var.user_password
      temporary = false
    }
    // Add more users here
  ]
}
