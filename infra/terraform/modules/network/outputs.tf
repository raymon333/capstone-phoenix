output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "subnet_id" {
  value = azurerm_subnet.nodes.id
}

output "location" {
  value = azurerm_resource_group.this.location
}