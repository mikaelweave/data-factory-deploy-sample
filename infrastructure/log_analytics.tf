resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.base_name}-${var.environment}-la"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_key_vault_secret" "log_analytics_workspace_id" {
  name         = "LOG-ANALYTICS-WORKSPACE-ID"
  value        = azurerm_log_analytics_workspace.logs.workspace_id
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "log_analytics_key" {
  name         = "LOG-ANALYTICS-PRIMARY-KEY"
  value        = azurerm_log_analytics_workspace.logs.primary_shared_key
  key_vault_id = azurerm_key_vault.keyvault.id
}