output "bridge_name" {
  value = routeros_bridge.main.name
}

output "routeros_ip_services" {
  value = data.routeros_ip_services.self.services
}
