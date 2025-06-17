resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.env}-${var.project_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_function {
    function = var.function_name
  }
  project = var.project_id
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.env}-${var.project_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
  project = var.project_id
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.env}-${var.project_name}-urlmap"
  default_service = google_compute_backend_service.backend_service.self_link
  project = var.project_id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.env}-${var.project_name}-proxy"
  url_map = google_compute_url_map.url_map.self_link
  project = var.project_id
}

resource "google_compute_global_address" "lb_ip" {
  name = "${var.env}-${var.project_name}-ip"
  project = var.project_id
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "${var.env}-${var.project_name}-fwdrule"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.lb_ip.id
  project = var.project_id
}
