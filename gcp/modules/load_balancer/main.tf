resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_function {
    function = var.function_name
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "serverless-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_address" "default" {
  name = "lb-ip"
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-forwarding-rule"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.default.id
}
