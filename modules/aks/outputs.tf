output "aks_id" { value = azurerm_kubernetes_cluster.aks.id }
output "aks_kubelet_object_id" { value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id }

