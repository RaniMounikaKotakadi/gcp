resource "google_compute_network" "function_vpc" {
  name                    = "${var.env}-${var.project_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "function_subnet" {
  name          = "${var.env}-${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.function_vpc.id
  project       = var.project_id
}

resource "google_vpc_access_connector" "function_connector" {
  name          = "${var.env}-${var.project_name}-vpc-connector"
  region        = var.region
  network       = google_compute_network.function_vpc.name
  ip_cidr_range = var.connector_cidr
  project       = var.project_id
}
