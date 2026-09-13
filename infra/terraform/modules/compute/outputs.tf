output "server_public_ip"   { value = azurerm_public_ip.server.ip_address }
output "server_private_ip"  { value = azurerm_network_interface.server.private_ip_address }
output "agent_public_ips"   { value = azurerm_public_ip.agent[*].ip_address }
output "agent_private_ips"  { value = azurerm_network_interface.agent[*].private_ip_address }