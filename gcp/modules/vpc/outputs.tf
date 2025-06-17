output "vpc_connector" {
  description = "Name of the VPC connector"
  value       = google_vpc_access_connector.function_connector.name
}

output "subnet_self_link" {
  value = google_compute_subnetwork.function_subnet.self_link
}
