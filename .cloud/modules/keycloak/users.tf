resource "keycloak_user" "user" {
  for_each = { for user in var.users : user.tf_id => user }

  realm_id   = keycloak_realm.default.id
  username   = each.value.username
  enabled    = each.value.enabled
  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  attributes = each.value.attributes

  initial_password {
    value     = each.value.password
    temporary = each.value.temporary
  }
}