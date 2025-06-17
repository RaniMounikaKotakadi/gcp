output "lb_ip" {
  description = "The external IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}
