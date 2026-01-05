provider "keycloak" {
  client_id     = "admin-cli"
  username      = "admin"
  password      = "admin"
  url           = var.server_url
  tls_insecure_skip_verify = true
  initial_login            = false # Bypasses the version check on startup
}