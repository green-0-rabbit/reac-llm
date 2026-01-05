resource "azurerm_public_ip" "pip" {
  count = var.public_ip != null ? 1 : 0

  name                = var.public_ip.name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip.allocation_method
  sku                 = "Standard"
  sku_tier            = var.public_ip.sku_tier
  tags                = var.tags
  zones               = var.zones
}

resource "azurerm_application_gateway" "agw" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = var.zones

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name = trusted_root_certificate.value.name
      data = trusted_root_certificate.value.data
    }
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.value.name
      port = frontend_port.value.port
    }
  }

  frontend_ip_configuration {
    name                 = "my-frontend-ip-configuration"
    public_ip_address_id = var.public_ip != null ? azurerm_public_ip.pip[0].id : null
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value.name
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = probe.value.name
      host                                      = probe.value.host
      interval                                  = probe.value.interval
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings

      dynamic "match" {
        for_each = probe.value.match != null ? [probe.value.match] : []
        content {
          body        = match.value.body
          status_code = match.value.status_code
        }
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value.name
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      host_name                           = backend_http_settings.value.host_name
      path                                = backend_http_settings.value.path
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      probe_name                          = backend_http_settings.value.probe_name
      request_timeout                     = backend_http_settings.value.request_timeout
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_certificate_names

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate != null ? backend_http_settings.value.authentication_certificate : []
        content {
          name = authentication_certificate.value.name
        }
      }

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining != null ? [backend_http_settings.value.connection_draining] : []
        content {
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
          enabled           = connection_draining.value.enable_connection_draining
        }
      }
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name != null ? http_listener.value.frontend_ip_configuration_name : "my-frontend-ip-configuration"
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.ssl_certificate_name == null ? "Http" : "Https"
      firewall_policy_id             = http_listener.value.firewall_policy_id
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      ssl_profile_name               = http_listener.value.ssl_profile_name

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? http_listener.value.custom_error_configuration : []
        content {
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
          status_code           = custom_error_configuration.value.status_code
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = request_routing_rule.value.rule_type
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      priority                    = request_routing_rule.value.priority
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "private_link_configuration" {
    for_each = var.private_link_configuration != null ? var.private_link_configuration : []
    content {
      name = private_link_configuration.value.name

      dynamic "ip_configuration" {
        for_each = private_link_configuration.value.ip_configuration
        content {
          name                          = ip_configuration.value.name
          subnet_id                     = ip_configuration.value.subnet_id
          private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
          primary                       = ip_configuration.value.primary
          private_ip_address            = ip_configuration.value.private_ip_address
        }
      }
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_sets
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rules
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = rewrite_rule.value.conditions
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = rewrite_rule.value.request_header_configurations
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configurations
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = rewrite_rule.value.url != null ? [rewrite_rule.value.url] : []
            content {
              path         = url.value.path
              query_string = url.value.query_string
              components   = url.value.components
              reroute      = url.value.reroute
            }
          }
        }
      }
    }
  }

  firewall_policy_id = var.firewall_policy_id

  tags = var.tags
}
