output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "primary_access_key" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true
}

output "primary_file_endpoint" {
  value = azurerm_storage_account.this.primary_file_endpoint
}

output "share_urls" {
  value = { for k, v in azurerm_storage_share.shares : k => v.url }
}
