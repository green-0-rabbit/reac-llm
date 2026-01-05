resource "keycloak_role" "realm_role" {
  for_each    = { for role in var.realm_roles : role.name => role }
  realm_id    = keycloak_realm.default.id
  name        = each.value.name
  description = each.value.description

  attributes = {
    for attr in each.value.attributes : attr.key => attr.value
  }
}