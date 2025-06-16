resource "google_compute_network" "function_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "function_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.function_vpc.id
}

resource "google_vpc_access_connector" "function_connector" {
  name          = var.connector_name
  region        = var.region
  network       = google_compute_network.function_vpc.name
  ip_cidr_range = var.connector_cidr  
}