data "azurerm_subscription" "current" {
}

output "current_subscription" {
  value = data.azurerm_subscription.current.display_name
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "public_ips" {
  value = azurerm_public_ip.main[*].ip_address
}