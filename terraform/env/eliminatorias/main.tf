module "network" {
  source = "../../modules/network"

  resource_group_name = "rg-copa-001"
  location            = var.location
  vnet_name           = "vnet-copa-001"
  vnet_address_space  = "10.1.0.0/16"
  nsg_name            = "nsg-copa-001"

  subnets = {
    "snet-copa-001" = "10.1.1.0/24"
    "snet-copa-002" = "10.1.2.0/24"
  }

  nsg_rules = {
    "allow-rdp" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "allow-ssh" = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
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

module "vm_windows" {
  source = "../../modules/compute"

  vm_name             = "vm-copa-001"
  location            = var.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.subnet_ids["snet-copa-001"]
  vm_size             = "Standard_B2als_v2"
  os_type             = "windows"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  public_ip_name      = "vm-copa-001-ip"
  disk_type           = "StandardSSD_LRS"
  disk_size_gb        = 128

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-azure-edition"
    version   = "latest"
  }

  hotpatch_enabled = true
  tags             = var.tags
}

module "vm_linux" {
  source = "../../modules/compute"

  vm_name             = "vm-copa-002"
  location            = var.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.subnet_ids["snet-copa-002"]
  vm_size             = "Standard_B2als_v2"
  os_type             = "linux"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  public_ip_name      = "vm-copa-002-ip"
  disk_type           = "StandardSSD_LRS"
  disk_size_gb        = 30

  image = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = var.tags
}

module "storage" {
  source = "../../modules/storage"

  storage_account_name     = "stcopaazuretftec26"
  resource_group_name      = module.network.resource_group_name
  location                 = var.location
  replication_type         = "LRS"
  allow_blob_public_access = true

  containers = {
    "imagens" = "blob"
  }

  file_shares = {
    "files-copa" = 5
  }

  tags = var.tags
}
