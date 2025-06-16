output "vpc_connector" {
  description = "Name of the VPC connector"
  value       = google_vpc_access_connector.function_connector.name
}