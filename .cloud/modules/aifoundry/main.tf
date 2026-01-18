#########################################################
# AI Foundry instance using Azapi
#########################################################

resource "random_string" "unique" {
	length     = 3
	min_numeric = 3
	numeric    = true
	special    = false
	lower      = true
	upper      = false
}

locals {
	resource_group_id   = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.target_rg}"
	resource_name       = "${var.application_id}-${var.environment}-${random_string.unique.result}"
	resource_name_compact = "${var.application_id}${var.environment}${random_string.unique.result}"
}

# AI Foundry account (without network injection)
resource "azapi_resource" "ai_foundry" {
	type      = "Microsoft.CognitiveServices/accounts@2025-09-01"
	name      = "aif-${local.resource_name}"
	parent_id = local.resource_group_id
	location  = var.location
	identity {
		type = "SystemAssigned"
	}
	schema_validation_enabled = false

	body = {
		kind = var.kind
		sku = {
			name = var.sku_name
		}

		properties = {
			# API properties
			apiProperties = {}
			allowProjectManagement = true
			customSubDomainName = "sbx-aif-${local.resource_name}"

			# Network-related controls (simplified without VNet injection)
			publicNetworkAccess = var.public_network_access_enabled ? "Enabled" : "Disabled"
		}
	}
}

#########################################################
# Create a deployment for OpenAI's GPT-4o in the AI Foundry resource
#########################################################
resource "azurerm_cognitive_deployment" "aifoundry_deployment" {
	for_each = var.models
	name = "${each.key}-${each.value.sku}"
	#cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
	cognitive_account_id = azapi_resource.ai_foundry.id

	sku {
		name     = each.value.sku
		capacity = each.value.capacity
	}

	model {
		format  = each.value.format
		name    = each.key
		version = each.value.version
	}

	version_upgrade_option = "NoAutoUpgrade"
	rai_policy_name        = azurerm_cognitive_account_rai_policy.content_filter.name
	depends_on = [
		#azurerm_cognitive_account.ai_foundry
		azapi_resource.ai_foundry
	]
}

#########################################################
# Apply content filtering to the model
#########################################################
resource "azurerm_cognitive_account_rai_policy" "content_filter" {
	name = "base_content_filter"
	#cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
	cognitive_account_id = azapi_resource.ai_foundry.id
	base_policy_name     = "Microsoft.DefaultV2"

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "Violence"
		source             = "Prompt"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "Hate"
		source             = "Prompt"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "Sexual"
		source             = "Prompt"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "SelfHarm"
		source             = "Prompt"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "Violence"
		source             = "Completion"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "Hate"
		source             = "Completion"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "Sexual"
		source             = "Completion"
	}

	content_filter {
		severity_threshold = "High"
		block_enabled      = true
		filter_enabled     = true
		name               = "SelfHarm"
		source             = "Completion"
	}
}

#########################################################
# Create private endpoint for AI Foundry
#########################################################
resource "azurerm_private_endpoint" "ai_foundry_pe" {
	name                = "pe-aif-${local.resource_name}"
	location            = var.location
	resource_group_name = var.target_rg
	subnet_id           = var.networking.subnet_id

	private_service_connection {
		name                           = "ai-foundry-psc"
		is_manual_connection           = false
		#private_connection_resource_id = azurerm_cognitive_account.ai_foundry.id
		private_connection_resource_id = azapi_resource.ai_foundry.id
		subresource_names              = ["account"]
	}

	dynamic "private_dns_zone_group" {
		for_each = var.dns.register_pe_to_dns == true ? toset([1]) : toset([])
		content {
			name                 = "pe-aif-${local.resource_name}-dns"
			private_dns_zone_ids = var.dns.ai_foundry_dns_ids
		}
	}

	# Cognitive Services Endpoint
	dynamic "ip_configuration" {
		for_each = var.networking.static_ip_address_allocation == true ? toset([1]) : toset([])
		content {
			name               = "cs-pe-ip-config"
			private_ip_address = var.networking.cognitive_services_pe_ip
			subresource_name   = "account"
			member_name        = "default"
		}
	}

	# Open AI Endpoint
	dynamic "ip_configuration" {
		for_each = var.networking.static_ip_address_allocation == true ? toset([1]) : toset([])
		content {
			name               = "oai-pe-ip-config"
			private_ip_address = var.networking.openai_pe_ip
			subresource_name   = "account"
			member_name        = "secondary"
		}
	}

	# Services Endpoint
	dynamic "ip_configuration" {
		for_each = var.networking.static_ip_address_allocation == true ? toset([1]) : toset([])
		content {
			name               = "services-pe-ip-config"
			private_ip_address = var.networking.services_pe_ip
			subresource_name   = "account"
			member_name        = "third"
		}
	}
}
