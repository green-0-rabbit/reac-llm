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

resource "keycloak_user_roles" "user_roles" {
  for_each = {
    for user in var.users : user.tf_id => user
    if length(user.roles) > 0
  }

  realm_id = keycloak_realm.default.id
  user_id  = keycloak_user.user[each.key].id

  role_ids = [
    for role in each.value.roles : keycloak_role.realm_role[role].id
  ]
}