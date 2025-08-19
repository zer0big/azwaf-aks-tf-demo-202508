output "hub_vnet_id" {
  value = azurerm_virtual_network.hub_vnet.id
}

output "ingress_vnet_id" {
  value = azurerm_virtual_network.spoke_ingress_vnet.id
}

output "aks_vnet_id" {
  value = azurerm_virtual_network.spoke_aks_vnet.id
}

output "hub_mgmt_subnet_id" {
  value = azurerm_subnet.mgmt_subnet.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgateway_subnet.id
}

output "aks_system_subnet_id" {
  value = azurerm_subnet.aks_system_subnet.id
}

output "aks_user_subnet_id" {
  value = azurerm_subnet.aks_user_subnet.id
}

output "firewall_private_ip" {
  value = azurerm_firewall.fw.ip_configuration[0].private_ip_address
}

output "firewall_id" { value = azurerm_firewall.fw.id }
