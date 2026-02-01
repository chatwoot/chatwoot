# --- Configuración del Proveedor y Backend de Terraform ---
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }

  # RECOMENDACIÓN: Configura un backend remoto en un bucket de GCS
  # para almacenar el estado de Terraform de forma segura y colaborativa.
  # backend "gcs" {
  #   bucket  = "nombre-de-tu-bucket-tf-state"
  #   prefix  = "gke/production"
  # }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# --- Activación de APIs necesarias ---
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com"
  ])
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = true
}

# --- Red (VPC) y Conexión Privada para Cloud SQL ---
resource "google_compute_network" "vpc" {
  name                    = "chatwoot-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "chatwoot-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.gcp_region
}

# Reserva de Rango IP para la conexión de servicios privados (necesario para Cloud SQL)
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-for-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.apis]
}


# --- Clúster de Kubernetes (GKE) ---
resource "google_container_cluster" "primary" {
  name     = "${var.cluster_name}-cluster"
  location = var.gcp_region
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  initial_node_count = 1
  remove_default_node_pool = true

  # Asegura que la conexión de red privada esté lista antes de crear el clúster
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = false
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# --- Base de Datos PostgreSQL (Cloud SQL) ---
resource "google_sql_database_instance" "postgres" {
  name             = "${var.db_instance_name}"
  database_version = "POSTGRES_13"
  region           = var.gcp_region

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled    = false # No IP pública
      private_network = google_compute_network.vpc.id
    }
    # Recomendación: Habilitar backups
    backup_configuration {
      enabled = true
    }
  }

  # Asegura que la conexión de red privada esté lista
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

# --- Usuario y Contraseña de la Base de Datos ---
# Genera una contraseña aleatoria si no se provee una.
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Usa la contraseña del tfvars si existe, si no, usa la generada.
locals {
  db_password = var.db_password != "" ? var.db_password : random_password.db_password.result
}

resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = local.db_password
}

# --- Salidas (Outputs) ---
output "kubernetes_cluster_name" {
  description = "Nombre del clúster de GKE."
  value       = google_container_cluster.primary.name
}

output "db_instance_connection_name" {
  description = "Nombre de conexión de la instancia de Cloud SQL para el Auth Proxy."
  value       = google_sql_database_instance.postgres.connection_name
}

output "db_name" {
  description = "Nombre de la base de datos."
  value       = google_sql_database.database.name
}

output "db_user" {
  description = "Usuario de la base de datos."
  value       = google_sql_user.db_user.name
}

output "db_password" {
  description = "Contraseña de la base de datos (¡manejar con cuidado!)."
  value       = local.db_password
  sensitive   = true
}