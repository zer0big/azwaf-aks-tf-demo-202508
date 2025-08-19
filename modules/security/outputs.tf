output "kv_id" { value = azurerm_key_vault.kv.id }
output "kv_name" { value = azurerm_key_vault.kv.name }
output "acr_id" { value = azurerm_container_registry.acr.id }
output "acr_login_server" { value = azurerm_container_registry.acr.login_server }

