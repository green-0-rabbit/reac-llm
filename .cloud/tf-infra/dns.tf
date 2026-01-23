locals {
  azure_monitor_private_dns_zones = toset([
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
  ])

  azure_ai_private_dns_zones = toset([
    "privatelink.services.ai.azure.com",       # AI Services Private DNS Zone
    "privatelink.search.windows.net",          # AI Search Private DNS Zone
    "privatelink.openai.azure.com",            # Cognitive Services Private DNS Zone
    "privatelink.cognitiveservices.azure.com", # Cognitive Services General Private DNS Zone
  ])
}


# Private DNS zone lives in the backbone RG
resource "azurerm_private_dns_zone" "sbx_zone" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS zone for PostgreSQL Flexible Server
resource "azurerm_private_dns_zone" "postgres" {
  name                = "sbx-kag.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

# Azure Monitor / AMPLS required zones

resource "azurerm_private_dns_zone" "ampls" {
  for_each            = local.azure_monitor_private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}


# Azure AI services AIfoundry DNS

# see @https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-ai-foundry/tree/v0.10.0/examples/private
resource "azurerm_private_dns_zone" "aifoundry" {
  for_each            = local.azure_ai_private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}

