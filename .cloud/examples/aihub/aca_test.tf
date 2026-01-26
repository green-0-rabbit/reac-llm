# module "frontend_aihub_fix" {
#   source = "../../modules/container_app"

#   app_config = {
#     name                  = "ai-hub-frontend-fix"
#     revision_mode         = "Single"
#     workload_profile_name = module.container_app_environment.workload_profile_name
#   }
#   environment                  = var.env
#   location                     = var.location
#   resource_group_name          = azurerm_resource_group.rg.name
#   container_app_environment_id = module.container_app_environment.id

#   user_assigned_identity = {
#     id           = azurerm_user_assigned_identity.containerapp.id
#     principal_id = azurerm_user_assigned_identity.containerapp.principal_id
#   }

#   registry_fqdn = local.acr_login_server
#   acr_id        = data.azurerm_container_registry.acr.id
#   kv_id         = azurerm_key_vault.this.id

#   ingress = {
#     external_enabled = true
#     target_port      = 8080
#     traffic_weight = [
#       {
#         latest_revision = true
#         percentage      = 100
#       }
#     ]
#   }

#   secrets                    = []
#   create_acr_role_assignment = false

#   template = {
#     min_replicas = 1
#     max_replicas = 1
#     containers = [
#       {
#         name   = "ai-hub-frontend-fix"
#         image  = "humaapi0registry/frontend-demo-fix:latest"
#         cpu    = 0.5
#         memory = "1Gi"
#         env = [
#           {
#             name  = "API_URL"
#             value = "https://${local.backend_aihub_fqdn}"
#           },
#           {
#             name  = "SESSION_REPLAY_KEY"
#             value = ""
#           },
#           {
#             name  = "PIANO_ANALYTICS_SITE_ID"
#             value = ""
#           },
#           {
#             name  = "PIANO_ANALYTICS_COLLECTION_DOMAIN"
#             value = ""
#           }
#         ]
#       }
#     ]
#   }
# }

# module "todo_app_api" {
#   source = "../../modules/container_app"

#   app_config = {
#     name                  = "todo-app-api"
#     revision_mode         = "Single"
#     workload_profile_name = module.container_app_environment.workload_profile_name
#   }
#   environment                  = var.env
#   location                     = var.location
#   resource_group_name          = azurerm_resource_group.rg.name
#   container_app_environment_id = module.container_app_environment.id

#   user_assigned_identity = {
#     id           = azurerm_user_assigned_identity.containerapp.id
#     principal_id = azurerm_user_assigned_identity.containerapp.principal_id
#   }

#   create_acr_role_assignment = false

#   registry_fqdn = local.acr_login_server
#   acr_id        = data.azurerm_container_registry.acr.id
#   kv_id         = azurerm_key_vault.this.id

#   ingress = {
#     external_enabled = true
#     target_port      = 3001
#     traffic_weight = [
#       {
#         latest_revision = true
#         percentage      = 100
#       }
#     ]
#   }

#   secrets = [
#     {
#       name  = "database-password"
#       value = var.admin_password
#     }
#   ]

#   template = {
#     min_replicas = 1
#     max_replicas = 1
#     containers = [
#       {
#         name = "todo-app-api"
#         # Placeholder image - user needs to build this
#         image  = "humaapi0registry/todo-app-api:latest"
#         cpu    = 0.5
#         memory = "1Gi"
#         env = [
#           {
#             name  = "PORT"
#             value = "3001"
#           },
#           {
#             name  = "NODE_ENV"
#             value = "prod"
#           },
#           # Database Configuration
#           {
#             name  = "DATABASE_HOST"
#             value = module.postgres_todoapi.fqdn
#           },
#           {
#             name  = "DATABASE_PORT"
#             value = "5432"
#           },
#           {
#             name  = "DATABASE_SCHEMA"
#             value = "todo_db"
#           },
#           {
#             name  = "DATABASE_USERNAME"
#             value = azurerm_user_assigned_identity.containerapp.name
#           },
#           # {
#           #   name        = "DATABASE_PASSWORD"
#           #   secret_name = "database-password"
#           # },
#           # Storage Configuration (Managed Identity)
#           {
#             name  = "AZURE_STORAGE_SERVICE_URI"
#             value = azurerm_storage_account.this.primary_blob_endpoint
#           },
#           {
#             name  = "AZURE_STORAGE_CONTAINER_NAME"
#             value = "todo-app-container"
#           },
#           {
#             name  = "AZURE_CLIENT_ID"
#             value = azurerm_user_assigned_identity.containerapp.client_id
#           },
#           # AI Foundry Configuration (Managed Identity)
#           {
#             name  = "API_ENDPOINT"
#             value = module.ai_foundry.openai_endpoint
#           },
#           {
#             name  = "API_MODEL_NAME"
#             value = "gpt-4.1-GlobalStandard"
#           },
#           {
#             name  = "API_VERSION"
#             value = "2024-10-21"
#           }
#         ]
#       }
#     ]
#   }
# }

# resource "azurerm_role_assignment" "openai_user" {
#   scope                = module.ai_foundry.ai_foundry_id
#   role_definition_name = "Cognitive Services OpenAI User"
#   principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
# }