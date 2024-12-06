
resource "azurerm_resource_group" "this" {
  name     = "BTCAPI-Function-App-${var.name}"
  location = "NorthEurope"
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
  source                 = "${path.root}/../data/btcusd_1-day_data.csv.zip"
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