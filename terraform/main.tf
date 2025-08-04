provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.id

  secondary_ip_range {
    range_name    = "pods-range"          # ✅ match this
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range"      # ✅ match this
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_firewall" "egress_to_master" {
  name      = "allow-egress-to-gke-master"
  network   = google_compute_network.vpc_network.name
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  destination_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

resource "google_compute_firewall" "internal_traffic" {
  name      = "allow-internal"
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  source_ranges = ["10.10.0.0/16"]

  allow {
    protocol = "all"
  }
}

resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

resource "google_container_cluster" "gke_cluster" {
  name     = "secure-gke-cluster"
  location = var.region

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"        # ✅ must match subnetwork
    services_secondary_range_name = "services-range"    # ✅ must match subnetwork
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    service_account = google_service_account.gke_node_sa.email  # ✅ use created SA
  }

  depends_on = [google_service_account.gke_node_sa] # ✅ make sure SA exists before cluster
}


