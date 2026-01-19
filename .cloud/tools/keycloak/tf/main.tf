module "local_keycloak" {
  source = "../../../modules/keycloak"

  realm_config = {
    otp_enabled                    = true
    login_with_email_allowed       = true
    registration_email_as_username = true
    verify_email                   = false
    ssl_required                   = "external"
  }
  default_realm_name = var.default_realm_name

  realm_private_key = var.aihub_saml_private_key
  realm_certificate = var.aihub_saml_certificate

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
    {
      name = "ADMIN"
      attributes = []
    },
    {
      name = "VIEWER"
      attributes = []
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

  saml_clients = [
    {
      client_id                           = "aihub-prod"
      name                                = "aihub-prod"
      sign_documents                      = true
      sign_assertions                     = true
      encrypt_assertions                  = false
      client_signature_required           = false
      force_post_binding                  = false
      front_channel_logout                = true
      protocol_mappers = [
        {
          name                       = "email"
          user_property              = "email"
          saml_attribute_name        = "email"
          saml_attribute_name_format = "Basic"
        },
        {
          name                       = "firstName"
          user_property              = "firstName"
          saml_attribute_name        = "firstName"
          saml_attribute_name_format = "Basic"
        },
        {
          name                       = "lastName"
          user_property              = "lastName"
          saml_attribute_name        = "lastName"
          saml_attribute_name_format = "Basic"
        }
      ]
      name_id_format                      = "email"
      valid_redirect_uris                 = ["http://localhost:3002/auth/saml/callback"]
      assertion_consumer_post_url         = "http://localhost:3002/auth/saml/callback"
      assertion_consumer_redirect_url     = "http://localhost:3002/auth/saml/callback"
      logout_service_post_binding_url     = "http://localhost:3002/auth/logout"
      logout_service_redirect_binding_url = "http://localhost:3002/auth/logout"
      signing_certificate                 = var.aihub_saml_certificate
      signing_private_key                 = var.aihub_saml_private_key
      signature_algorithm                 = "RSA_SHA256"
    }
  ]

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
      roles     = ["ADMIN"]
    }
    // Add more users here
  ]
}
