variable "application_id" {
	description = "The application id"
	type        = string
	nullable    = false
}

variable "location" {
	description = "The name of the Azure region where to provision the resources"
	type        = string
	nullable    = false
}

variable "environment" { type = string }

variable "public_network_access_enabled" {
	type        = bool
	description = "Public network access for the Container Apps environment."
	default     = false
}

variable "tags" {
	description = "A mapping of tags to assign to the resources. will be merged with the mandatory tags"
	type        = map(string)
	default     = {}
}

variable "target_rg" {
	description = "Target resource groupe where the resource will be created"
	type        = string
	nullable    = false
}

variable "kind" {
	description = "Specifies the type of Cognitive Service Account that should be created"
	type        = string
	nullable    = false

	validation {
		condition     = contains(["AIServices", "OpenAI"], var.kind)
		error_message = "The environment must be OpenAI or AIServices."
	}
}

variable "sku_name" {
	description = "Specifies the SKU Name for this Cognitive Service Account"
	type        = string
	nullable    = false

	validation {
		condition     = contains(["C2", "C3", "C4", "D3", "DC0", "E0", "F0", "F1", "P0", "P1", "P2", "S", "S0", "S1", "S2", "S3", "S4", "S5", "S6"], var.sku_name)
		error_message = "Possible values are C2, C3, C4, D3, DC0, E0, F0, F1, P0, P1, P2, S, S0, S1, S2, S3, S4, S5 and S6"
	}
}

variable "networking" {
	type = object({
		subnet_id                    = string
		static_ip_address_allocation = optional(bool, false)
		cognitive_services_pe_ip     = optional(string)
		openai_pe_ip                 = optional(string)
		services_pe_ip               = optional(string)
	})
	nullable = false

	validation {
		condition = (var.networking.static_ip_address_allocation
			&& can(cidrnetmask("${var.networking.cognitive_services_pe_ip}/32"))
			&& can(cidrnetmask("${var.networking.openai_pe_ip}/32"))
			&& can(cidrnetmask("${var.networking.services_pe_ip}/32"))
		) || !var.networking.static_ip_address_allocation
		error_message = "Network configuration is incorrect"
	}
}

variable "dns" {
	description = "DNS configuration for AI Foundry"
	type = object({
		register_pe_to_dns = optional(bool, false)
		ai_foundry_dns_ids = optional(list(string), [])
	})
	nullable = false

	validation {
		condition = (var.dns.register_pe_to_dns
			&& length(var.dns.ai_foundry_dns_ids) > 2
		) || !var.dns.register_pe_to_dns
		error_message = "DNS configuration is incorrect"
	}
}

variable "models" {
	description = "List of models to deploy on AI Foundry"
	type = map(object({
		version  = string
		capacity = optional(number, 5)
		sku      = optional(string, "GlobalStandard")
		format   = optional(string, "OpenAI")
	}))
	nullable = false
}
