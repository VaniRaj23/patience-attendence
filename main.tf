provider "google" {
  project     = "fluid-acrobat-440707-v4"
  region      = "us-central1"
  zone        = "us-central1-a"
  credentials = "/home/pushparajpolakala/.config/gcloud/application_default_credentials.json"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
}

# Public Subnet with separate secondary ranges for Pods and Services
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"

  # Secondary range for Pods
  secondary_ip_range {
    range_name    = "public-pods-range"
    ip_cidr_range = "192.168.0.0/16"
  }

  # Secondary range for Services
  secondary_ip_range {
    range_name    = "public-services-range"
    ip_cidr_range = "192.169.0.0/16"
  }
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
}

# GKE Cluster
resource "google_container_cluster" "gke_cluster" {
  name                      = "my-gke-cluster"
  location                  = "us-central1"
  network                   = google_compute_network.vpc_network.id
  subnetwork                = google_compute_subnetwork.public_subnet.id
  remove_default_node_pool  = true  # Removes the default node pool

  # Assign distinct secondary IP ranges for Pods and Services
  ip_allocation_policy {
    cluster_secondary_range_name  = "public-pods-range"
    services_secondary_range_name = "public-services-range"
  }

  initial_node_count = 1  # Temporarily set to 1 for minimal configuration
}

# Node Pool for the GKE Cluster
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = google_container_cluster.gke_cluster.location
  cluster    = google_container_cluster.gke_cluster.name

  node_config {
    machine_type = "e2-medium"  # Specify machine type based on needs
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  initial_node_count = 1
}

