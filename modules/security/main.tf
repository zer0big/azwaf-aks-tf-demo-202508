resource "random_id" "rid" {
  byte_length = 4
}

# 값을 안 넘겨주면 자동으로 고유 이름 생성
locals {
  kv_name  = var.key_vault_name != "" ? var.key_vault_name : "kv-zerobig-${random_id.rid.hex}"
  acr_name = var.acr_name != "" ? var.acr_name : "acrzerobig${random_id.rid.hex}"
}

# Key Vault (Private)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                          = local.kv_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = false
  tags                          = var.tags
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

# VNet Links (Hub/AKS/Ingress 모두 연결)
resource "azurerm_private_dns_zone_virtual_network_link" "kv_link_hub" {
  name                  = "kv-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_link_aks" {
  name                  = "kv-aks"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = var.aks_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_link_ingress" {
  name                  = "kv-ing"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = var.ingress_vnet_id
  registration_enabled  = false
}

# Private Endpoint (Key Vault)
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.hub_pe_subnet_id

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdzg-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_zone.id]
  }

  tags = var.tags
}

# ACR (Premium)
resource "azurerm_container_registry" "acr" {
  name                          = local.acr_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = var.tags
}

# ACR Private DNS Zones (registry + data)
resource "azurerm_private_dns_zone" "acr_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "acr_data_zone" {
  name                = "privatelink.${var.region_code}.data.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_link_hub" {
  name                  = "acr-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_zone.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_link_aks" {
  name                  = "acr-aks"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_zone.name
  virtual_network_id    = var.aks_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_data_link_hub" {
  name                  = "acr-data-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_data_zone.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_data_link_aks" {
  name                  = "acr-data-aks"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_data_zone.name
  virtual_network_id    = var.aks_vnet_id
  registration_enabled  = false
}

# Private Endpoint (ACR registry)
resource "azurerm_private_endpoint" "acr_pe" {
  name                = "pe-acr"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.hub_pe_subnet_id

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name = "pdzg-acr"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.acr_zone.id,
      azurerm_private_dns_zone.acr_data_zone.id
    ]
  }

  tags = var.tags
}

