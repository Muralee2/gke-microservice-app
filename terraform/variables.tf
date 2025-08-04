variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "network_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "gke_node_sa_email" {
  type        = string
  description = "The email of the GKE node service account"
}
