resource "google_service_account" "lb_invoker" {
  account_id   = var.name
  display_name = "Load Balancer Invoker"
}
