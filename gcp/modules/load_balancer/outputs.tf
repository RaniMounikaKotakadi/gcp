output "backend_service_name" {
  value = google_compute_backend_service.default.name
}

output "lb_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}
