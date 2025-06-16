resource "google_project_iam_member" "lb_invoker_binding" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${var.lb_invoker_sa_email}"
}
