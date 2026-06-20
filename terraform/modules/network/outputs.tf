output "resource_group_name" {
  value = local.rg_name
}

output "resource_group_location" {
  value = local.rg_location
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_id" {
  value = azurerm_network_security_group.this.id
}
