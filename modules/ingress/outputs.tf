# App Gateway 리소스 ID
output "appgw_id" {
  value = azurerm_application_gateway.appgw.id
}

# App Gateway의 Public IP (리소스 이름 확인 필요: pip/pip_agw/appgw_pip 중 실제 사용명)
output "appgw_public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
