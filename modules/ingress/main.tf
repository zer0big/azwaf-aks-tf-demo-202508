# User Assigned Identity for AppGW
resource "azurerm_user_assigned_identity" "uai" {
  name                = var.uai_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Public IP for AppGW
resource "azurerm_public_ip" "pip" {
  name                = var.appgw_pip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# (옵션) AppGW에 Key Vault 인증서 연결용 블록
# kv_cert_secret_id가 전달된 경우에만 사용
locals {
  use_kv_cert = length(var.kv_cert_secret_id) > 0
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  waf_configuration {
    enabled            = true
    firewall_mode      = "Prevention"
    rule_set_type      = "OWASP"
    rule_set_version   = "3.2"
    request_body_check = true
  }

  gateway_ip_configuration {
    name      = "gwipc"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "fp-80"
    port = 80
  }

  # HTTPS 포트(미리 생성)
  frontend_port {
    name = "fp-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "be-dummy"
  }

  backend_http_settings {
    name                                = "bhs-80"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = false
    cookie_based_affinity               = "Disabled"
  }

  http_listener {
    name                           = "listener-80"
    frontend_ip_configuration_name = "feip"
    frontend_port_name             = "fp-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule-80"
    rule_type                  = "Basic"
    http_listener_name         = "listener-80"
    backend_address_pool_name  = "be-dummy"
    backend_http_settings_name = "bhs-80"
    priority                   = 100
  }

  autoscale_configuration {
    min_capacity = var.appgw_min_capacity
    max_capacity = var.appgw_max_capacity
  }

  # HTTPS 리스너/규칙은 kv-cert가 연결된 후 Ingress가 관리해도 됨
  # (원하면 여기서도 ssl_certificate 블록으로 선 등록 가능)

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai.id]
  }
}

