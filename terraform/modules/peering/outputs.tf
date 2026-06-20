output "peering_source_to_dest_id" {
  value = azurerm_virtual_network_peering.source_to_dest.id
}
output "peering_dest_to_source_id" {
  value = azurerm_virtual_network_peering.dest_to_source.id
}
