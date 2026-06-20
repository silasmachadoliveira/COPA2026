resource "azurerm_public_ip" "this" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_windows_virtual_machine" "this" {
  count = var.os_type == "windows" ? 1 : 0

  name                  = var.vm_name
  computer_name         = var.computer_name != "" ? var.computer_name : substr(replace(var.vm_name, "-", ""), 0, 15)
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.this.id]
  patch_mode            = var.hotpatch_enabled ? "AutomaticByPlatform" : "AutomaticByOS"
  hotpatching_enabled   = var.hotpatch_enabled
  tags                  = var.tags

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.disk_type
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }
}

resource "azurerm_virtual_machine_extension" "winrm" {
  count = var.os_type == "windows" ? 1 : 0

  name                 = "enable-winrm"
  virtual_machine_id   = azurerm_windows_virtual_machine.this[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Set-Item WSMan:\\localhost\\Service\\Auth\\Basic -Value $true; Set-Item WSMan:\\localhost\\Service\\AllowUnencrypted -Value $false; New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\\LocalMachine\\My | ForEach-Object { New-Item -Path WSMan:\\localhost\\Listener -Transport HTTPS -Address * -CertificateThumbPrint $_.Thumbprint -Force }; New-NetFirewallRule -Name WinRM-HTTPS -DisplayName 'WinRM HTTPS' -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow; Restart-Service WinRM\""
  })
}

resource "azurerm_mssql_virtual_machine" "this" {
  count = var.sql_enabled ? 1 : 0

  virtual_machine_id               = azurerm_windows_virtual_machine.this[0].id
  sql_license_type                 = "PAYG"
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_username = var.admin_username
  sql_connectivity_update_password = var.admin_password

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "GENERAL"

    data_settings {
      default_file_path = "F:\\SQLData"
      luns              = [0]
    }

    log_settings {
      default_file_path = "G:\\SQLLog"
      luns              = [1]
    }

    temp_db_settings {
      default_file_path = "H:\\SQLTempDB"
      luns              = [2]
    }
  }

  depends_on = [
    azurerm_managed_disk.sql,
    azurerm_virtual_machine_data_disk_attachment.sql,
    azurerm_virtual_machine_extension.winrm
  ]
}

resource "azurerm_managed_disk" "sql" {
  count = var.sql_enabled ? 3 : 0

  name                 = "${var.vm_name}-sqldisk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.sql_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql" {
  count = var.sql_enabled ? 3 : 0

  managed_disk_id    = azurerm_managed_disk.sql[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.this[0].id
  lun                = count.index
  caching            = "ReadOnly"
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.os_type == "linux" ? 1 : 0

  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.this.id]
  tags                            = var.tags

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.disk_type
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }
}
