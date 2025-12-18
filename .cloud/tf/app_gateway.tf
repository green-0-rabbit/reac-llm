resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "agw-${var.env}-wafpolicy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

module "application_gateway" {
  source = "../modules/application_gateway"

  name                = "agw-${var.env}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  subnet_id           = module.vnet-spoke1.subnet_ids["ApplicationGatewaySubnet"]
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf_policy.id

  public_ip = {
    name = "agw-${var.env}-pip"
  }

  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  frontend_ports = {
    port_80 = {
      name = "port_80"
      port = 80
    }
  }

  backend_address_pools = {
    default = {
      name  = "default-backend-pool"
      fqdns = [local.container_app_fqdn]
    }
  }

  trusted_root_certificates = {
    containerapp_cert = {
      name = "containerapp-root-cert"
      data = data.local_file.der.content_base64
    }
  }

  backend_http_settings = {
    default = {
      name                                = "default-http-settings"
      cookie_based_affinity               = "Disabled"
      path                                = "/"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = 60
      pick_host_name_from_backend_address = true
      trusted_root_certificate_names      = ["containerapp-root-cert"]
    }
  }

  http_listeners = {
    default = {
      name                           = "default-listener"
      frontend_ip_configuration_name = "my-frontend-ip-configuration"
      frontend_port_name             = "port_80"
      protocol                       = "Http"
    }
  }

  request_routing_rules = {
    default = {
      name                       = "default-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "default-listener"
      backend_address_pool_name  = "default-backend-pool"
      backend_http_settings_name = "default-http-settings"
      priority                   = 100
      rewrite_rule_set_name      = "x-forwarded-host-rewrite"
    }
  }

  rewrite_rule_sets = {
    x_forwarded_host = {
      name = "x-forwarded-host-rewrite"
      rewrite_rules = [
        {
          name          = "inject-x-forwarded-host"
          rule_sequence = 100
          request_header_configurations = [
            {
              header_name  = "X-Forwarded-Host"
              header_value = "{http_req_host}"
            }
          ]
        }
      ]
    }
  }

  private_link_configuration = [{
    name = "agw-private-link"
    ip_configuration = [{
      name                          = "agw-private-link-ip"
      subnet_id                     = module.vnet-spoke1.subnet_ids["ApplicationGatewaySubnet"]
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }]
  }]

  tags = var.tags
}
