output "gke_cluster_name" {
  value = google_container_cluster.gke_cluster.name
}

output "endpoint" {
  value = google_container_cluster.gke_cluster.endpoint
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}
