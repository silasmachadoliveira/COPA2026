# --- Resource Group (único, Central India) ---
resource "azurerm_resource_group" "this" {
  name     = "rg-prd-tk-cin-001"
  location = "centralindia"
  tags     = var.tags
}

# --- Rede Central India (Frontend + Backend) ---
module "network_cin" {
  source = "../../modules/network"

  create_resource_group = false
  resource_group_name   = azurerm_resource_group.this.name
  location              = "centralindia"
  vnet_name             = "vnet-prd-inf-cin-001"
  vnet_address_space    = "10.20.0.0/16"
  nsg_name              = "nsg-prd-inf-cin-001"

  subnets = {
    "snet-prd-inf-fend-cin-001" = "10.20.1.0/24"
    "snet-prd-inf-bend-cin-001" = "10.20.2.0/24"
  }

  nsg_rules = {
    "allow-http" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "allow-https" = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "allow-rdp" = {
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = var.my_ip
      destination_address_prefix = "*"
    }
    "allow-http-internal" = {
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "10.20.0.0/16"
      destination_address_prefix = "*"
    }
    "allow-winrm" = {
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5986"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# --- Rede Australia East (Data) ---
module "network_aes" {
  source = "../../modules/network"

  create_resource_group = false
  resource_group_name   = azurerm_resource_group.this.name
  location              = "australiaeast"
  vnet_name             = "vnet-prd-inf-aes-001"
  vnet_address_space    = "10.30.0.0/16"
  nsg_name              = "nsg-prd-inf-aes-001"

  subnets = {
    "snet-prd-inf-data-aes-001" = "10.30.1.0/24"
  }

  nsg_rules = {
    "allow-sql" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.20.0.0/16"
      destination_address_prefix = "*"
    }
    "allow-rdp" = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = var.my_ip
      destination_address_prefix = "*"
    }
    "allow-winrm" = {
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5986"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# --- Global VNet Peering ---
module "peering" {
  source = "../../modules/peering"

  source_vnet_name           = "vnet-prd-inf-cin-001"
  source_vnet_id             = module.network_cin.vnet_id
  source_resource_group_name = azurerm_resource_group.this.name
  dest_vnet_name             = "vnet-prd-inf-aes-001"
  dest_vnet_id               = module.network_aes.vnet_id
  dest_resource_group_name   = azurerm_resource_group.this.name
}

# --- VM Frontend (IIS + ARR) ---
module "vm_frontend" {
  source = "../../modules/compute"

  vm_name             = "vm-prd-tk-fend-cin-001"
  computer_name       = "TKFEND001"
  location            = "centralindia"
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network_cin.subnet_ids["snet-prd-inf-fend-cin-001"]
  vm_size             = "Standard_B2als_v2"
  os_type             = "windows"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  public_ip_name      = "pip-prd-tk-fend-cin-001"
  disk_type           = "StandardSSD_LRS"
  disk_size_gb        = 128

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = var.tags
}

# --- VM Backend (Node.js API) ---
module "vm_backend" {
  source = "../../modules/compute"

  vm_name             = "vm-prd-tk-bend-cin-001"
  computer_name       = "TKBEND001"
  location            = "centralindia"
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network_cin.subnet_ids["snet-prd-inf-bend-cin-001"]
  vm_size             = "Standard_B2als_v2"
  os_type             = "windows"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  public_ip_name      = "pip-prd-tk-bend-cin-001"
  disk_type           = "StandardSSD_LRS"
  disk_size_gb        = 128

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = var.tags
}

# --- VM Data (SQL Server 2022) ---
module "vm_data" {
  source = "../../modules/compute"

  vm_name             = "vm-prd-tk-data-aes-001"
  computer_name       = "TKDATA001"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network_aes.subnet_ids["snet-prd-inf-data-aes-001"]
  vm_size             = "Standard_B2als_v2"
  os_type             = "windows"
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
  public_ip_name      = "pip-prd-tk-data-aes-001"
  disk_type           = "StandardSSD_LRS"
  disk_size_gb        = 128

  image = {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "sqldev-gen2"
    version   = "latest"
  }

  sql_enabled      = true
  sql_disk_size_gb = 8
  tags             = var.tags
}
