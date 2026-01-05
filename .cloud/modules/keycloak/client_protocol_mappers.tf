resource "keycloak_generic_protocol_mapper" "audience-mapper" {
  realm_id        = keycloak_realm.default.id
  client_id       = keycloak_openid_client.sso.id
  name            = "audience-mapper"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-audience-mapper"
  config = {
    "included.client.audience" = var.client_sso.client_id,
    "id.token.claim"           = true,
    "access.token.claim"       = true
  }
}