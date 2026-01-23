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
resource "keycloak_saml_client" "saml_client" {
  for_each = { for client in var.saml_clients : client.client_id => client }

  realm_id  = keycloak_realm.default.id
  client_id = each.value.client_id
  name      = coalesce(each.value.name, each.value.client_id)

  sign_documents            = each.value.sign_documents
  sign_assertions           = each.value.sign_assertions
  encrypt_assertions        = each.value.encrypt_assertions
  client_signature_required = each.value.client_signature_required
  force_post_binding        = each.value.force_post_binding
  front_channel_logout      = each.value.front_channel_logout
  name_id_format            = each.value.name_id_format

  valid_redirect_uris = each.value.valid_redirect_uris

  assertion_consumer_post_url         = each.value.assertion_consumer_post_url
  assertion_consumer_redirect_url     = each.value.assertion_consumer_redirect_url
  logout_service_post_binding_url     = each.value.logout_service_post_binding_url
  logout_service_redirect_binding_url = each.value.logout_service_redirect_binding_url

  signing_certificate = each.value.signing_certificate
  signing_private_key = each.value.signing_private_key
  signature_algorithm = each.value.signature_algorithm

  idp_initiated_sso_url_name = each.value.idp_initiated_sso_url_name

}
