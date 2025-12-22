resource "keycloak_realm" "default" {
  realm                          = var.default_realm_name
  registration_allowed           = false
  reset_password_allowed         = var.realm_config.reset_password_allowed
  access_code_lifespan           = var.realm_config.access_code_lifespan
  remember_me                    = var.realm_config.remember_me
  edit_username_allowed          = var.realm_config.edit_username_allowed
  login_with_email_allowed       = var.realm_config.login_with_email_allowed
  registration_email_as_username = var.realm_config.registration_email_as_username
  verify_email                   = var.realm_config.verify_email
}