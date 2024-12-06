# Fetch Azure client configuration
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "BTCAPI-Function-App-${var.name}"
  location = "NorthEurope"
}

# Key Vault
resource "azurerm_key_vault" "this" {
  name                     = "BTCAPI-FuncApp-KV-${var.name}"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  # Access policy for a specific identity (Service Principal or Managed Identity)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",  # Allow the identity to retrieve secrets
      "List", # Optional: Allows listing secrets
      "Set"   # Optional: Allows setting secrets
    ]
  }
}

# Managed Identity
resource "azurerm_user_assigned_identity" "kv-storage-blob" {
  name                = "kv-storage-blob"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_key_vault_access_policy" "kv-storage-blob" {
  key_vault_id = azurerm_key_vault.this.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.kv-storage-blob.principal_id

  secret_permissions = [
    "Get", # Allow the identity to retrieve secrets
    "List" # Optional: Allows listing secrets
  ]
}

resource "azurerm_application_insights" "this" {
  name                = "BTCAPI-Function-App-AppInsights-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
}

resource "azurerm_storage_account" "this" {
  name                     = "btcapifuncappsa${var.name}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "data" {
  name               = "btcdata"
  storage_account_id = azurerm_storage_account.this.id
}
resource "azurerm_storage_blob" "btcusd_1-day_data_csv_zip" {
  name                   = "btcusd_1-day_data.csv.zip"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  # It's in a folder called data seperate from the app and infrastructure
  source = "${path.root}/../data/btcusd_1-day_data.csv.zip"
}

# Key Vault Secret (Example: Storage Account Key)
resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "StorageAccountKey"
  value        = azurerm_storage_account.this.primary_access_key
  key_vault_id = azurerm_key_vault.this.id
}

# Assign the Managed Identity Access to Key Vault
resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.kv-storage-blob.principal_id
}

# Assign the Managed Identity Access to Storage Account
resource "azurerm_role_assignment" "storage_access" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.kv-storage-blob.principal_id
}

# Assign the Managed Identity Access to Storage Account
resource "azurerm_role_assignment" "function_app_access" {
  scope                = azurerm_linux_function_app.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.kv-storage-blob.principal_id
}

resource "azurerm_service_plan" "this" {
  name                = "btcapi-azurerm-service-plan-${var.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "this" {
  name                       = "btcapi-azure-functions-${var.name}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  service_plan_id            = azurerm_service_plan.this.id

  app_settings = {
    application_insights_connection_string = azurerm_application_insights.this.instrumentation_key
    # This allows terraform to deploy to it, otherwise it expects a package to be uploaded
    WEBSITE_RUN_FROM_PACKAGE = 0
    # WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    # WEBSITES_MOUNT_ENABLED              = 1
    # FUNCTIONS_WORKER_RUNTIME            = "python"
    # AzureWebJobsStorage                 = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.this.name};AccountKey=${azurerm_storage_account.this.primary_access_key}"
    # Reference Key Vault secret
    "MySecretSetting" = "@Microsoft.KeyVault(SecretUri=https://${azurerm_key_vault.this.name}.vault.azure.net/secrets/StorageAccountKey/)"
  }
  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

# Never Works
# resource "azurerm_function_app_function" "example" {
#   name            = "get_historic_bitcoin_price"
#   function_app_id = azurerm_linux_function_app.this.id
#   language        = "Python"

#   file {
#     # name    = "get_historic_bitcoin_price.py"
#     # content = file("get_historic_bitcoin_price/get_historic_bitcoin_price.py")
#     name    = "http_trigger2"
#     content = file("functions/function_app.py")
#   }

#   test_data = jsonencode({
#     "name" = "Azure"
#   })

#   config_json = jsonencode({
#     "bindings" = [
#       {
#         "authLevel" = "function"
#         "direction" = "in"
#         "methods" = [
#           "get",
#           "post",
#         ]
#         "name" = "req"
#         "type" = "httpTrigger"
#       },
#       {
#         "direction" = "out"
#         "name"      = "$return"
#         "type"      = "http"
#       },
#     ]
#   })
# }