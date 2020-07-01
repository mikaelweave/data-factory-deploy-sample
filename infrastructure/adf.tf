resource "azurerm_data_factory" "adf" {
    name = "${var.base_name}-${var.environment}-adf"
    location = var.location
    resource_group_name = azurerm_resource_group.rg.name
    
    identity {
        type = "SystemAssigned"
    }

    github_configuration {
        # count           = length(var.adf_link_github == true ? 1 : 0)
        git_url         = "https://github.com"
        account_name    = var.adf_account_name
        repository_name = var.adf_repository_name
        branch_name     = var.adf_branch_name
        root_folder     = "/data-factory/"
    }
}

resource "azurerm_monitor_diagnostic_setting" "data_factory_logs" {
    name = "${var.base_name}-${var.environment}-adf-logs"
    target_resource_id = azurerm_data_factory.adf.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
    log_analytics_destination_type = "Dedicated"
    
    log {
        category = "ActivityRuns"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }

    log {
        category = "PipelineRuns"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }

    log {
        category = "TriggerRuns"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }
}
