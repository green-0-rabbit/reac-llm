resource "keycloak_openid_client" "sso" {
  realm_id                     = keycloak_realm.default.id
  client_id                    = var.client_sso.client_id
  enabled                      = var.client_sso.enabled
  direct_access_grants_enabled = var.client_sso.direct_access_grants_enabled
  standard_flow_enabled        = var.client_sso.standard_flow_enabled
  access_type                  = var.client_sso.access_type
  valid_redirect_uris          = var.client_sso.valid_redirect_uris
  login_theme                  = var.client_sso.login_theme
  full_scope_allowed           = var.client_sso.full_scope_allowed
}