output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry account."
  value       = azapi_resource.ai_foundry.id
}

output "ai_foundry_name" {
  description = "The name of the AI Foundry account."
  value       = azapi_resource.ai_foundry.name
}

output "openai_endpoint" {
  description = "OpenAI endpoint for the AI Foundry account."
  value       = "https://sbx-aif-${local.resource_name}.openai.azure.com"
}

output "cognitive_deployment_id" {
  value = { for k, v in azurerm_cognitive_deployment.aifoundry_deployment : k => v.id }
}

output "private_endpoint_network_interface" {
  value = azurerm_private_endpoint.ai_foundry_pe.network_interface
}