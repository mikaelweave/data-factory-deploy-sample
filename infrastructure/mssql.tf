resource "azurerm_sql_server" "server" {
  name                         = "${var.base_name}-${var.environment}-server"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = random_pet.mssqladminusername.id
  administrator_login_password = random_password.mssqladminpassword.result
}

resource "azurerm_sql_database" "db" {
  name                             = "${var.base_name}-${var.environment}-db"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = var.location
  server_name                      = azurerm_sql_server.server.name
  edition                          = "GeneralPurpose"
  requested_service_objective_name = "GP_S_Gen5_4"
}

resource "random_pet" "mssqladminusername" {
  keepers = {
    # Generate a new pet name each time we switch to a new SQL Server Name
    sql_server_id = "${var.base_name}-${var.environment}-server"
  }
}

resource "random_password" "mssqladminpassword" {
  length = 16
  special = true
  min_upper = 3
  min_lower = 3
  min_numeric = 2
  min_special = 2
  override_special = "_%@"
}

resource "azurerm_sql_firewall_rule" "azure" {
    name = "AllowAllWindowsAzureIps"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_sql_server.server.name
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "0.0.0.0"
}


resource "azurerm_sql_firewall_rule" "deployer" {
    name = "DeployingServer"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_sql_server.server.name
    start_ip_address    = chomp(data.http.icanhazip.body)
    end_ip_address      = chomp(data.http.icanhazip.body)
}


resource "azurerm_sql_active_directory_administrator" "sql-dw-server-admin" {
  server_name         = azurerm_sql_server.server.name
  resource_group_name = azurerm_resource_group.rg.name
  login               = "sqladmin"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

resource "azurerm_monitor_diagnostic_setting" "mssql_logs" {
    name                       = "${var.base_name}-${var.environment}-logs"
    target_resource_id         = azurerm_sql_database.db.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

    log {
        category = "SQLSecurityAuditEvents"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }
}

locals {
  auditActionsAndGroups = ["USER_CHANGE_PASSWORD_GROUP", "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP"]
}

resource "azurerm_template_deployment" "sql-audit-enable" {
  name                = "sql-audit-enable"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = file("sql-audit.json")
  deployment_mode = "Incremental"

  parameters = {
    "serverName"   = azurerm_sql_server.server.name
    "databaseName" = azurerm_sql_database.db.name
    "auditActionGroups" = "${join(",", local.auditActionsAndGroups)}"
  }
}

resource "azurerm_key_vault_secret" "sql_admin_username" {
  name         = "SQL-ADMIN-USERNAME"
  value        = random_pet.mssqladminusername.id
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "SQL-ADMIN-PASSWORD"
  value        = random_password.mssqladminpassword.result
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "sql_hostname" {
  name         = "SQL-HOSTNAME"
  value        = azurerm_sql_server.server.fully_qualified_domain_name
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "sql_dbname" {
  name         = "SQL-DBNAME"
  value        = azurerm_sql_database.db.name
  key_vault_id = azurerm_key_vault.keyvault.id
}