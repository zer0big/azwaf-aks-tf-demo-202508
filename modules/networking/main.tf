# Hub VNet
resource "azurerm_virtual_network" "hub_vnet" {
  name                = var.hub_vnet_name
  address_space       = [var.hub_vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Subnets (Firewall / Mgmt / PrivateEndpoint)
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_subnet" "mgmt_subnet" {
  name                 = "MgmtSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "pe_subnet" {
  name                 = "PrivateEndpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Ingress VNet
resource "azurerm_virtual_network" "spoke_ingress_vnet" {
  name                = var.ingress_vnet_name
  address_space       = [var.spoke_ingress_vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "appgateway_subnet" {
  name                 = "AppGatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke_ingress_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# AKS VNet
resource "azurerm_virtual_network" "spoke_aks_vnet" {
  name                = var.aks_vnet_name
  address_space       = [var.spoke_aks_vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "aks_system_subnet" {
  name                 = "AksSystem"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke_aks_vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_subnet" "aks_user_subnet" {
  name                 = "AksUser"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke_aks_vnet.name
  address_prefixes     = ["10.20.2.0/24"]
}

# VNet Peering (양방향)
resource "azurerm_virtual_network_peering" "hub_to_ingress" {
  name                      = "hub-to-ingress"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_ingress_vnet.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "ingress_to_hub" {
  name                      = "ingress-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke_ingress_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "hub_to_aks" {
  name                      = "hub-to-aks"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_aks_vnet.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "aks_to_hub" {
  name                      = "aks-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke_aks_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic   = true
}

# Firewall Policy
resource "azurerm_firewall_policy" "policy" {
  name                     = "fp-${var.tags.env}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"
  tags                     = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "rcg" {
  name               = "rcg-allow-egress"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 100

  application_rule_collection {
    name     = "allow-aks-acr"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "aks-platform"
      source_addresses      = ["10.20.0.0/16", "10.10.0.0/16"]
      destination_fqdn_tags = ["AzureKubernetesService"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "acr-mcr"
      source_addresses  = ["10.20.0.0/16", "10.10.0.0/16"]
      destination_fqdns = ["*.azurecr.io", "*.data.azurecr.io", "mcr.microsoft.com", "*.blob.core.windows.net"]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "time-service"
      source_addresses  = ["10.20.0.0/16", "10.10.0.0/16"]
      destination_fqdns = ["time.windows.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "allow-dns"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "dns-udp"
      source_addresses      = ["10.20.0.0/16", "10.10.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "dns-tcp"
      source_addresses      = ["10.20.0.0/16", "10.10.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
      protocols             = ["TCP"]
    }
  }
}

# Firewall + PIP
resource "azurerm_public_ip" "firewall_pip" {
  name                = "pip-fw-${var.tags.env}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "fw" {
  name                = "fw-zerobig"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "AZFW_VNet"
  sku_tier = "Premium"

  firewall_policy_id = azurerm_firewall_policy.policy.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  tags = var.tags
}

# Route Table (AKS 서브넷에만 연동; AppGW Subnet에는 연동하지 않음)
resource "azurerm_route_table" "rt" {
  name                = "rt-to-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "default" {
  name                   = "default-to-fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "aks_system" {
  subnet_id      = azurerm_subnet.aks_system_subnet.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_subnet_route_table_association" "aks_user" {
  subnet_id      = azurerm_subnet.aks_user_subnet.id
  route_table_id = azurerm_route_table.rt.id
}

