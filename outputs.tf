# AppGW Public IP 출력
output "appgw_public_ip" {
  value = module.ingress.appgw_public_ip
}

# 보조 출력 (이미 있으면 유지)
output "firewall_private_ip" {
  value = module.networking.firewall_private_ip
}

output "law_workspace_id" {
  value = module.monitoring.law_id
}

