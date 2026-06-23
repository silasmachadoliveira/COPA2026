# --- Resource Group PaaS ---
resource "azurerm_resource_group" "this" {
  name     = "rg-prd-tk-paas-cin-001"
  location = var.location
  tags     = var.tags
}

# --- VNet (para Private Endpoints + VNet Integration) ---
resource "azurerm_virtual_network" "this" {
  name                = "vnet-prd-paas-cin-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.40.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "appsvc" {
  name                 = "snet-prd-appsvc-cin-001"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.40.1.0/24"]

  delegation {
    name = "appservice"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-prd-pe-cin-001"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.40.2.0/24"]
}

# --- App Service Plan ---
resource "azurerm_service_plan" "this" {
  name                = "asp-prd-tk-cin-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = "B1"
  tags                = var.tags
}

# --- Web App Backend (API) ---
resource "azurerm_windows_web_app" "backend" {
  name                = "app-prd-tk-bend-cin-sm001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  site_config {
    application_stack {
      node_version = "~20"
    }
    always_on  = false
    ftps_state = "Disabled"
  }

  app_settings = {
    "JWT_SECRET"    = "copa2026-tftec-jwt-secret-key-ultra-segura"
    "JWT_EXPIRES_IN" = "7d"
    "FRONTEND_URL"  = "https://copaazure2026.silasmachado.cloud"
    "DB_SERVER"     = "sql-prd-tk-cin-sm001.database.windows.net"
    "DB_PORT"       = "1433"
    "DB_USER"       = var.sql_admin_username
    "DB_PASSWORD"   = var.sql_admin_password
    "DB_NAME"       = "FIFA2026Tickets"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Server=tcp:sql-prd-tk-cin-sm001.database.windows.net,1433;Database=FIFA2026Tickets;User Id=${var.sql_admin_username};Password=${var.sql_admin_password};Encrypt=true;TrustServerCertificate=false"
  }
}

# --- Web App Frontend ---
resource "azurerm_windows_web_app" "frontend" {
  name                = "app-prd-tk-fend-cin-sm001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  site_config {
    application_stack {
      node_version = "~20"
    }
    always_on  = false
    ftps_state = "Disabled"
  }

  app_settings = {}
}

# --- Azure SQL Server ---
resource "azurerm_mssql_server" "this" {
  name                         = "sql-prd-tk-cin-sm001"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.this.name
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.tags
}

# --- Azure SQL Database ---
resource "azurerm_mssql_database" "this" {
  name      = "FIFA2026Tickets"
  server_id = azurerm_mssql_server.this.id
  sku_name  = "Basic"
  tags      = var.tags
}

# --- SQL Firewall: allow Azure services ---
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "my_ip" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = var.my_ip
  end_ip_address   = var.my_ip
}

# --- Private Endpoint for SQL ---
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-prd-tk-cin-sm001"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

# --- Private DNS Zone for SQL ---
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_dns_a_record" "sql" {
  name                = "sql-prd-tk-cin-sm001"
  zone_name           = azurerm_private_dns_zone.sql.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address]
}
