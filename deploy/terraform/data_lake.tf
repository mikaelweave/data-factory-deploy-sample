resource "azurerm_storage_account" "datalake" {
    name                      = "${replace(replace(var.base_name, "-", ""), "_", "")}${var.environment}"
    resource_group_name       = azurerm_resource_group.rg.name
    location                  = var.location
    account_tier              = "Standard"
    account_replication_type  = "LRS"
    enable_https_traffic_only = "true"
    account_kind              = "StorageV2"
    is_hns_enabled            = "true"
}

resource "azurerm_monitor_diagnostic_setting" "storage_logs" {
    name = "${var.base_name}-${var.environment}-datalake-logs"
    target_resource_id = "${azurerm_storage_account.datalake.id}/blobServices/default"
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

    log {
        category = "StorageRead"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }

    log {
        category = "StorageWrite"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }

    log {
        category = "StorageDelete"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }
}