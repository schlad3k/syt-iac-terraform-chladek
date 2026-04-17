output "load_balancer_ip" {
  description = "Öffentliche IPv4-Adresse des Load Balancers"
  value       = hcloud_load_balancer.web.ipv4
}

output "server_ips" {
  description = "Öffentliche IPv4-Adressen der Webserver"
  value = {
    for s in hcloud_server.web : s.name => s.ipv4_address
  }
}

output "server_status" {
  description = "Status der Webserver"
  value = {
    for s in hcloud_server.web : s.name => s.status
  }
}

output "url" {
  description = "URL zum Testen (Load Balancer)"
  value       = "http://${hcloud_load_balancer.web.ipv4}"
}
