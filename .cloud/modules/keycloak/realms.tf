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
  ssl_required                   = var.realm_config.ssl_required
}
resource "keycloak_realm_keystore_rsa" "realm_rsa" {
  count     = var.realm_private_key != null && var.realm_certificate != null ? 1 : 0
  realm_id  = keycloak_realm.default.id
  name      = "${var.default_realm_name}-rsa-generated"
  enabled   = true
  algorithm = "RS256"
  priority  = 200

  private_key = var.realm_private_key
  certificate = var.realm_certificate
}
