resource "google_service_account" "lb_invoker" {
  account_id   = "${var.env}-${var.project_name}-sa"
  display_name = "Load Balancer Invoker"
  project      = var.project_id
}
