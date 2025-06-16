resource "google_cloudfunctions2_function" "function" {
  name        = var.name
  location    = var.region

  build_config {
    runtime     = "python310"
    entry_point = "hello_world"
    source {
      storage_source {
        bucket = var.source_bucket
        object = var.source_object
      }
    }
  }

  service_config {
    available_memory = "256Mi"
    available_cpu    = "0.082"
    vpc_connector    = var.vpc_connector
    ingress_settings = "ALLOW_INTERNAL_AND_GCLB"

  }
}

resource "google_cloud_run_service_iam_member" "run_invoker" {
  count    = var.is_public ? 1 : 0
  role   = "roles/run.invoker"
  member = var.public_member
  location = var.region
  project  = var.project_id
  service  = google_cloudfunctions2_function.function.name
}