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

locals {
  saml_client_mappers = flatten([
    for client in var.saml_clients : [
      for mapper in client.protocol_mappers : {
        client_id                  = client.client_id
        name                       = mapper.name
        user_property              = mapper.user_property
        saml_attribute_name        = mapper.saml_attribute_name
        saml_attribute_name_format = mapper.saml_attribute_name_format
      }
    ]
  ])
}

resource "keycloak_saml_user_property_protocol_mapper" "saml_mapper" {
  for_each = {
    for mapper in local.saml_client_mappers : "${mapper.client_id}-${mapper.name}" => mapper
  }

  realm_id                   = keycloak_realm.default.id
  client_id                  = keycloak_saml_client.saml_client[each.value.client_id].id
  name                       = each.value.name
  user_property              = each.value.user_property
  saml_attribute_name        = each.value.saml_attribute_name
  saml_attribute_name_format = each.value.saml_attribute_name_format
}
