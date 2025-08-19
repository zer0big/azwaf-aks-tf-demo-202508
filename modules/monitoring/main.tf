# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  tags                = var.tags
}

# AppGW / Firewall 진단설정 (resource-specific 테이블)
locals {
  diag_targets = {
    for k, v in var.target_ids : k => v
  }
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  for_each                       = local.diag_targets
  name                           = "diag-${each.key}-to-law"
  target_resource_id             = each.value
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

