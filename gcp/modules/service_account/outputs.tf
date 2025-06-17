output "id" {
  value = google_service_account.lb_invoker.id
}

output "email" {
  description = "The email of the service account"
  value       = google_service_account.lb_invoker.email
}
