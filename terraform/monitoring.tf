# =====================================================================
# 1. LOG ANALYTICS WORKSPACE
# =====================================================================
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-secure-hubspoke-prod-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# =====================================================================
# 2. DIAGNOSTIC SETTINGS VOOR AZURE FIREWALL
# =====================================================================
resource "azurerm_monitor_diagnostic_setting" "fw_diag" {
  name                       = "firewall-diagnostics-to-law"
  target_resource_id         = azurerm_firewall.fw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AZFWNetworkRule"
  }

  enabled_log {
    category = "AZFWApplicationRule"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}