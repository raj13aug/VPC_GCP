data "google_compute_zones" "available" {
  region  = var.region
  project = var.project_id
}

locals {
  type  = ["public", "private"]
  zones = data.google_compute_zones.available.names
}

# VPC
resource "google_compute_network" "vpc_network" {
  name                            = "${var.name}-vpc"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
}

#PUBLIC SUBNETS

resource "google_compute_subnetwork" "subnetwork_public" {
  name          = "${var.name}-${local.type[0]}-subnetwork"
  ip_cidr_range = var.ip_cidr_range[0]
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# PRIVATE SUBNETS
resource "google_compute_subnetwork" "subnetwork_private" {
  name                     = "${var.name}-${local.type[1]}-subnetwork"
  ip_cidr_range            = var.ip_cidr_range[1]
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}


# NAT ROUTER
resource "google_compute_router" "router" {
  name    = "${var.name}-${local.type[0]}-router"
  region  = google_compute_subnetwork.subnetwork_public.region
  network = google_compute_network.vpc_network.id
}


resource "google_compute_router_nat" "router_nat" {
  name                               = "${var.name}-${local.type[0]}-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = "${var.name}-${local.type[0]}-subnetwork"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}