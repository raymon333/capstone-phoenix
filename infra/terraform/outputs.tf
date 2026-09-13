output "server_public_ip"  { value = module.compute.server_public_ip }
output "server_private_ip" { value = module.compute.server_private_ip }
output "agent_public_ips"  { value = module.compute.agent_public_ips }
output "agent_private_ips" { value = module.compute.agent_private_ips }