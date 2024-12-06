output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true
}

output "service_principal_id" {
  value = data.azurerm_client_config.current.object_id
}