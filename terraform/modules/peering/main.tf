resource "azurerm_virtual_network_peering" "source_to_dest" {
  name                      = "${var.source_vnet_name}-to-${var.dest_vnet_name}"
  resource_group_name       = var.source_resource_group_name
  virtual_network_name      = var.source_vnet_name
  remote_virtual_network_id = var.dest_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}

resource "azurerm_virtual_network_peering" "dest_to_source" {
  name                      = "${var.dest_vnet_name}-to-${var.source_vnet_name}"
  resource_group_name       = var.dest_resource_group_name
  virtual_network_name      = var.dest_vnet_name
  remote_virtual_network_id = var.source_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
}
