output "backend_url" {
  value = "https://${azurerm_windows_web_app.backend.default_hostname}"
}

output "frontend_url" {
  value = "https://${azurerm_windows_web_app.frontend.default_hostname}"
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}
