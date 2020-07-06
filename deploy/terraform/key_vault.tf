# Key Vault for access
resource "azurerm_key_vault" "keyvault" {
    name                        = "${var.base_name}-${var.environment}-kv"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    enabled_for_disk_encryption = true
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    sku_name = "standard"

    network_acls {
        default_action = "Allow"
        bypass         = "AzureServices"
    }
}

locals {
    admin_permissions_policy = {
        certificate = ["create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "setissuers", "update"]
        key = ["backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", "verify", "wrapKey"]
        secret = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
        storage = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
    }
}

locals {
    keyvault_admins_with_current = concat(var.keyvault_admin_object_ids, list(data.azurerm_client_config.current.object_id))
}

resource "azurerm_key_vault_access_policy" "admin" {
    count = length(local.keyvault_admins_with_current)

    key_vault_id = azurerm_key_vault.keyvault.id
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.keyvault_admins_with_current[count.index]
    key_permissions = local.admin_permissions_policy.key
    secret_permissions = local.admin_permissions_policy.secret
    storage_permissions = local.admin_permissions_policy.storage
    certificate_permissions = local.admin_permissions_policy.certificate
}

resource "azurerm_key_vault_access_policy" "reader" {
    count = length(var.keyvault_reader_object_ids)

    key_vault_id = azurerm_key_vault.keyvault.id
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.keyvault_reader_object_ids[count.index]
    secret_permissions = ["get", "list"]
}

resource "azurerm_monitor_diagnostic_setting" "keyvault_logs" {
    name = "${var.base_name}-${var.environment}-kv-logs"
    target_resource_id = azurerm_key_vault.keyvault.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

    log {
        category = "AuditEvent"
        enabled  = true

        retention_policy {
            enabled = false
        }
    }
}