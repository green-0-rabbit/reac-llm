variable "resource_group_name" {
  type        = string
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  type        = string
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network."
  default     = ""
}

variable "is_hub" {
  type        = bool
  description = "Boolean to indicate if the vNet is a hub vNet."
  default     = false
}

variable "vnet_address_space" {
  type        = set(string)
  description = "The address space to be used for the Azure virtual network."
  default     = ["10.2.0.0/16"]
}

variable "subnets" {
  description = "For each subnet, create an object that contain fields"
  type = map(object({
    subnet_address_prefix                         = list(string)
    service_endpoints                             = optional(list(string), [])
    private_link_service_network_policies_enabled = optional(bool, true)
    firewall_enabled                              = optional(bool, false)
    delegation = optional(object({
      name = optional(string)
      service_delegation = optional(object({
        name    = optional(string)
        actions = optional(list(string))
      }))
    }))

    nsg_inbound_rules = optional(map(object({
      priority                   = number
      direction                  = optional(string, "Inbound")
      access                     = optional(string, "Allow")
      protocol                   = optional(string, "Tcp")
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      destination_port_ranges    = optional(set(string), [])
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(set(string), [])
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {})

    nsg_outbound_rules = optional(map(object({
      priority                   = number
      direction                  = optional(string, "Outbound")
      access                     = optional(string, "Allow")
      protocol                   = optional(string, "Tcp")
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(set(string), [])
      destination_address_prefix = optional(string)
      description                = optional(string)
    })), {})
  }))
  default = {}
}

variable "remote_virtual_network_id" {
  type        = string
  description = "The id of hub virutal network"
  default     = ""
}

variable "remote_virtual_network_name" {
  type        = string
  description = "The name of remote virtual network"
  default     = ""
}

variable "remote_virtual_network_resource_group_name" {
  type        = string
  description = "The resource group name of the remote virtual network"
  default     = ""
}

variable "enable_peering" {
  type        = bool
  description = "Enable peering with remote virtual network"
  default     = false
}

variable "route_table_id" {
  type        = string
  description = "The ID of the route table to associate with the subnet"
  default     = ""
}

variable "firewall_private_ip_address" {
  type        = string
  description = "The private IP of the hub virtual network firewall"
  default     = null
}

variable "private_dns_zone_resource_group_name" {
  type        = string
  description = "The resource group name where the private DNS zones reside"
  default     = ""
}

variable "private_dns_zone_names" {
  description = "List of Private DNS Zone names to link to the VNet"
  type        = list(string)
  default     = []
}

variable "firewall" {
  type = object({
    sku_name              = optional(string, "AZFW_VNet")
    sku_tier              = optional(string, "Standard")
    subnet_address_prefix = optional(list(string), [])
    private_ip_address    = optional(string)
    service_endpoints = optional(list(string), [
      "Microsoft.AzureActiveDirectory",
      "Microsoft.AzureCosmosDB",
      "Microsoft.EventHub",
      "Microsoft.KeyVault",
      "Microsoft.ServiceBus",
      "Microsoft.Sql",
      "Microsoft.Storage",
    ])
    firewall_application_rules = optional(list(object({
      name             = string
      action           = string
      source_addresses = list(string)
      target_fqdns     = list(string)
      protocol = object({
        type = string
        port = string
      })
    })), [])
    firewall_network_rules = optional(list(object({
      name                  = string
      action                = string
      source_addresses      = list(string)
      destination_ports     = list(string)
      destination_addresses = list(string)
      protocols             = list(string)
    })), [])
    firewall_nat_rules = optional(list(object({
      name                  = string
      action                = string
      source_addresses      = list(string)
      destination_ports     = list(string)
      destination_addresses = list(string)
      translated_port       = number
      translated_address    = string
      protocols             = list(string)
    })), [])
  })
  description = "Configuration object for Azure Firewall"
  default     = null
}

# variable "log_analytics_workspace_id" {
#   description = "Specifies the id of the Log Analytics Workspace"
#   default     = ""
# }

# variable "log_analytics_customer_id" {
#   description = "The Workspace (or Customer) ID for the Log Analytics Workspace."
#   default     = ""
# }

# variable "log_analytics_logs_retention_in_days" {
#   description = "The log analytics workspace data retention in days. Possible values range between 30 and 730."
#   default     = ""
# }

# variable "nsg_diag_logs" {
#   description = "NSG Monitoring Category details for Azure Diagnostic setting"
#   default     = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
# }

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
