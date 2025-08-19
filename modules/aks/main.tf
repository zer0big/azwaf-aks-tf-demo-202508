resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  # Private AKS
  private_cluster_enabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                         = "systemnp"
    vm_size                      = var.system_vm_size
    node_count                   = var.system_node_count
    vnet_subnet_id               = var.aks_system_subnet_id
    only_critical_addons_enabled = true
  }

  # 네트워크
  network_profile {
    network_plugin    = "azure"              # Azure CNI
    outbound_type     = "userDefinedRouting" # Firewall 통해 UDR
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  # AGIC 애드온 (addon_profile 대신)
  ingress_application_gateway {
    gateway_id = var.appgw_id
  }

  tags = var.tags
}

# User Node Pool (일반 워크로드)
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "usernp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.aks_user_subnet_id
  mode                  = "User"
  orchestrator_version  = azurerm_kubernetes_cluster.aks.kubernetes_version

  tags = var.tags
}

# ACR Pull 권한 (Kubelet ID에 부여)
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

