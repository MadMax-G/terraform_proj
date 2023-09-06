output "web_vm_ip" {
  value = azurerm_public_ip.web_public_ip.ip_address
}

output "web_vm_port" {
  value = var.app_port
}

output "db_vm_ip" {
  value = azurerm_public_ip.database_public_ip.ip_address
}

output "rg_location" {
  value = var.location
}
output "web_ssh" {
  value = tls_private_key.vm_ssh.private_key_pem
  sensitive = true
}
