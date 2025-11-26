# ---------------------------------
# Module: VNET
# References:
# - https://github.com/kumarvna/terraform-azurerm-caf-virtual-network-spoke
# - https://github.com/kumarvna/terraform-azurerm-caf-virtual-network-hub
# - https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork

#-------------------------------------
# VNET Creation - Default is "true"
#-------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = lower("vnet-${var.vnet_name}-${var.location}")
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

#--------------------------------------------------------------------------------------------------------
# Subnets Creation with, private link endpoint/servie network policies, service endpoints and Deligation.
#--------------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "snet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.subnet_address_prefix
  service_endpoints    = each.value.service_endpoints
  # Applicable to the subnets which used for Private link endpoints or services 
  #   private_endpoint_network_policies = "Enabled"
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [1] : []
    content {
      name = each.value.delegation.name
      service_delegation {
        name    = each.value.delegation.service_delegation.name
        actions = each.value.delegation.service_delegation.actions
      }
    }
  }
}

#---------------------------------------------------------------
# Network security group - NSG created for every subnet in VNet
#---------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for k, v in var.subnets : k => v
    if length(v.nsg_inbound_rules) > 0 || length(v.nsg_outbound_rules) > 0
  }
  name                = lower("nsg_${each.key}_in")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge({ "ResourceName" = lower("nsg_${each.key}_in") }, var.tags, )
  dynamic "security_rule" {
    for_each = merge(each.value.nsg_inbound_rules, each.value.nsg_outbound_rules)
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = length(security_rule.value.source_address_prefixes) > 0 ? null : coalesce(security_rule.value.source_address_prefix, element(each.value.subnet_address_prefix, 0))
      destination_address_prefix = coalesce(security_rule.value.destination_address_prefix, element(each.value.subnet_address_prefix, 0))
      source_address_prefixes    = length(security_rule.value.source_address_prefixes) > 0 ? security_rule.value.source_address_prefixes : null
      description                = security_rule.value.description
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  for_each = {
    for k, v in var.subnets : k => v
    if length(v.nsg_inbound_rules) > 0 || length(v.nsg_outbound_rules) > 0
  }
  subnet_id                 = azurerm_subnet.snet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}



#---------------------------------------------
# Linking Vnet to Hub an existing Privates DNS zones
#---------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "dzvlink" {
  for_each              = toset(var.private_dns_zone_names)
  name                  = lower("${each.value}-link-to-${var.vnet_name}")
  resource_group_name   = coalesce(var.private_dns_zone_resource_group_name, var.resource_group_name)
  virtual_network_id    = azurerm_virtual_network.vnet.id
  private_dns_zone_name = each.value
  registration_enabled  = false
}

#-----------------------------------------------
# Peering between VNet and remote VNet (Hub)
#-----------------------------------------------
resource "azurerm_virtual_network_peering" "vnet_to_remote_vnet" {
  count                        = var.enable_peering ? 1 : 0
  name                         = lower("peering-to-remote-${element(split("/", var.remote_virtual_network_id), 8)}")
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.remote_virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "remote_vnet_to_vnet" {
  count                        = var.enable_peering ? 1 : 0
  name                         = lower("peering-${element(split("/", var.remote_virtual_network_id), 8)}-to-vnet-${var.vnet_name}")
  resource_group_name          = coalesce(var.remote_virtual_network_resource_group_name, var.resource_group_name)
  virtual_network_name         = var.remote_virtual_network_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}


#-----------------
# Azure Firewall 
#-----------------

locals {
  fw_application_rules = var.firewall != null ? { for idx, rule in var.firewall.firewall_application_rules : rule.name => { idx = idx, rule = rule } } : {}
  fw_network_rules     = var.firewall != null ? { for idx, rule in var.firewall.firewall_network_rules : rule.name => { idx = idx, rule = rule } } : {}
  fw_nat_rules         = var.firewall != null ? { for idx, rule in var.firewall.firewall_nat_rules : rule.name => { idx = idx, rule = rule } } : {}
}

resource "azurerm_public_ip" "fw-pip" {
  count               = var.firewall != null ? 1 : 0
  name                = lower("pip-fw-${var.vnet_name}-${var.location}")
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_subnet" "fw-snet" {
  count                = var.firewall != null ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.firewall.subnet_address_prefix
  service_endpoints    = var.firewall.service_endpoints
}


resource "azurerm_firewall" "fw" {
  count               = var.firewall != null ? 1 : 0
  name                = lower("fw-${var.vnet_name}-${var.location}")
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.firewall.sku_name
  sku_tier            = var.firewall.sku_tier

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.fw-snet[0].id
    public_ip_address_id = azurerm_public_ip.fw-pip[0].id
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.is_hub
      error_message = "The attribute is_hub must be true to configure firewall."
    }
  }
}

resource "azurerm_route_table" "rt_to_firewall" {
  count               = (var.firewall != null || var.firewall_private_ip_address != null) ? 1 : 0
  name                = "route-network-outbound"
  resource_group_name = var.resource_group_name
  location            = var.location

  route {
    name                   = lower("route-to-firewall-${var.vnet_name}-${var.location}")
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip_address != null ? var.firewall_private_ip_address : azurerm_firewall.fw[0].ip_configuration[0].private_ip_address
  }
  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "rtassoc" {
  for_each = {
    for k, v in var.subnets : k => v
    if v.firewall_enabled == true && (var.firewall != null || var.firewall_private_ip_address != null)
  }
  subnet_id      = azurerm_subnet.snet[each.key].id
  route_table_id = azurerm_route_table.rt_to_firewall[0].id
}

#----------------------------------------------
# Azure Firewall Network/Application/NAT Rules 
#----------------------------------------------


resource "azurerm_firewall_application_rule_collection" "fw_app" {
  for_each            = local.fw_application_rules
  name                = lower(format("fw-app-rule-%s-${var.vnet_name}-${var.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw[0].name
  resource_group_name = var.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name             = each.key
    source_addresses = each.value.rule.source_addresses
    target_fqdns     = each.value.rule.target_fqdns

    protocol {
      type = each.value.rule.protocol.type
      port = each.value.rule.protocol.port
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "fw" {
  for_each            = local.fw_network_rules
  name                = lower(format("fw-net-rule-%s-${var.vnet_name}-${var.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw[0].name
  resource_group_name = var.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name                  = each.key
    source_addresses      = each.value.rule.source_addresses
    destination_ports     = each.value.rule.destination_ports
    destination_addresses = each.value.rule.destination_addresses
    protocols             = each.value.rule.protocols
  }
}

resource "azurerm_firewall_nat_rule_collection" "fw" {
  for_each            = local.fw_nat_rules
  name                = lower(format("fw-nat-rule-%s-${var.vnet_name}-${var.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw[0].name
  resource_group_name = var.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name                  = each.key
    source_addresses      = each.value.rule.source_addresses
    destination_ports     = each.value.rule.destination_ports
    destination_addresses = [azurerm_public_ip.fw-pip[0].ip_address]
    protocols             = each.value.rule.protocols
    translated_address    = each.value.rule.translated_address
    translated_port       = each.value.rule.translated_port
  }
}

#---------------------------------------------------------------
# azurerm monitoring diagnostics - VNet, NSG, PIP, and Firewall
#---------------------------------------------------------------
# resource "azurerm_monitor_diagnostic_setting" "vnet" {
#   name                       = lower("vnet-${var.vnet_name}-diag")
#   target_resource_id         = azurerm_virtual_network.vnet.id
#   storage_account_id         = var.hub_storage_account_id
#   log_analytics_workspace_id = var.log_analytics_workspace_id

#  enabled_log {
#     category = "VMProtectionAlerts"
#     retention_policy {
#         enabled = false
#     }
#   }
#   enabled_metric {
#     category = "AllMetrics"
#   }
# }

# resource "azurerm_monitor_diagnostic_setting" "nsg" {
#   for_each                   = var.subnets
#   name                       = lower("${each.key}-diag")
#   target_resource_id         = azurerm_network_security_group.nsg[each.key].id
#   storage_account_id         = var.hub_storage_account_id
#   log_analytics_workspace_id = var.log_analytics_workspace_id

#   dynamic "enabled_log" {
#     for_each = var.nsg_diag_logs
#     content {
#       category = enabled_log.value

#       retention_policy {
#         enabled = false
#       }
#     }
#   }
# }
