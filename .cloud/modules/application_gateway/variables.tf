variable "name" {
  type        = string
  description = "The name of the application gateway."
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,78}[a-zA-Z0-9_]$", var.name))
    error_message = "The name must be 1-80 characters long, start with an alphanumeric character, end with an alphanumeric character or underscore, and contain only alphanumerics, underscores, periods, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "The resource group name must not be empty."
  }
}

variable "location" {
  type        = string
  description = "The Azure regional location where the resources will be deployed."
  validation {
    condition     = length(var.location) > 0
    error_message = "The azure region must not be empty."
  }
}

variable "public_ip" {
  description = "Configuration for the Public IP."
  type = object({
    name              = string
    sku_tier          = optional(string, "Regional")
    allocation_method = optional(string, "Static")
  })
  default = null

  validation {
    condition     = var.public_ip == null ? true : contains(["Global", "Regional"], var.public_ip.sku_tier)
    error_message = "The public IP SKU tier must be either 'Global' or 'Regional'."
  }
}

variable "zones" {
  description = "A collection of availability zones to spread the Application Gateway over."
  type        = list(string)
  default     = []
}

variable "trusted_root_certificates" {
  type = map(object({
    name = string
    data = string
  }))
  default     = {}
  description = "Map of trusted root certificates."
}

variable "backend_address_pools" {
  type = map(object({
    name         = string
    fqdns        = optional(set(string))
    ip_addresses = optional(set(string))
  }))
  description = "Map of backend address pools."
  nullable    = false
}

variable "sku" {
  type = object({
    name     = string
    tier     = string
    capacity = optional(number, 2)
  })
  default = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  description = "The SKU of the Application Gateway."
  validation {
    condition     = can(regex("^(Standard_v2|WAF_v2)$", var.sku.name))
    error_message = "SKU name must be 'Standard_v2' or 'WAF_v2'."
  }
  validation {
    condition     = can(regex("^(Standard_v2|WAF_v2)$", var.sku.tier))
    error_message = "SKU tier must be 'Standard_v2' or 'WAF_v2'."
  }
}

variable "request_routing_rules" {
  type = map(object({
    name                        = string
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = string
    priority                    = number
    url_path_map_name           = optional(string)
    backend_http_settings_name  = string
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
  }))
  description = "Map of request routing rules."
  nullable    = false
}

variable "http_listeners" {
  type = map(object({
    name                           = string
    frontend_port_name             = string
    frontend_ip_configuration_name = optional(string)
    firewall_policy_id             = optional(string)
    require_sni                    = optional(bool)
    host_name                      = optional(string)
    host_names                     = optional(list(string))
    ssl_certificate_name           = optional(string)
    ssl_profile_name               = optional(string)
    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })))
  }))
  description = "Map of HTTP listeners."
  nullable    = false
}

variable "frontend_ports" {
  type = map(object({
    name = string
    port = number
  }))
  description = "Map of frontend ports."
  nullable    = false
}

variable "backend_http_settings" {
  type = map(object({
    cookie_based_affinity               = optional(string, "Disabled")
    name                                = string
    port                                = number
    protocol                            = string
    affinity_cookie_name                = optional(string)
    host_name                           = optional(string)
    path                                = optional(string)
    pick_host_name_from_backend_address = optional(bool)
    probe_name                          = optional(string)
    request_timeout                     = optional(number)
    trusted_root_certificate_names      = optional(list(string))
    authentication_certificate = optional(list(object({
      name = string
    })))
    connection_draining = optional(object({
      drain_timeout_sec          = number
      enable_connection_draining = bool
    }))
  }))
  description = "Map of backend HTTP settings."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet for the Application Gateway."
}

variable "firewall_policy_id" {
  type        = string
  description = "The ID of the Web Application Firewall Policy."
}

variable "private_link_configuration" {
  type = set(object({
    name = string
    ip_configuration = list(object({
      name                          = string
      primary                       = bool
      private_ip_address            = optional(string)
      private_ip_address_allocation = string
      subnet_id                     = string
    }))
  }))
  default     = null
  description = "Privates Links Configuration for the Application Gateway"
}

variable "rewrite_rule_sets" {
  type = map(object({
    name = string
    rewrite_rules = list(object({
      name          = string
      rule_sequence = number
      conditions = optional(list(object({
        variable    = string
        pattern     = string
        ignore_case = optional(bool, false)
        negate      = optional(bool, false)
      })), [])
      request_header_configurations = optional(list(object({
        header_name  = string
        header_value = string
      })), [])
      response_header_configurations = optional(list(object({
        header_name  = string
        header_value = string
      })), [])
      url = optional(object({
        path         = optional(string)
        query_string = optional(string)
        components   = optional(string)
        reroute      = optional(bool)
      }))
    }))
  }))
  default     = {}
  description = "Map of rewrite rule sets."
}

variable "probes" {
  type = map(object({
    name                                      = string
    host                                      = optional(string)
    interval                                  = number
    protocol                                  = string
    path                                      = string
    timeout                                   = number
    unhealthy_threshold                       = number
    pick_host_name_from_backend_http_settings = optional(bool)
    match = optional(object({
      body        = optional(string)
      status_code = list(string)
    }))
  }))
  default     = {}
  description = "Map of health probes."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources."
}
