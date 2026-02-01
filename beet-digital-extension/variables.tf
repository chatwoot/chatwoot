variable "gcp_project_id" {
  description = "ID del proyecto de Google Cloud."
  type        = string
}

variable "gcp_region" {
  description = "Región de GCP donde se desplegarán los recursos."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Nombre base para el clúster de GKE."
  type        = string
  default     = "chatwoot-prod"
}

variable "node_count" {
  description = "Número de nodos en el clúster de GKE."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Tipo de máquina para los nodos de GKE."
  type        = string
  default     = "e2-medium"
}

variable "db_instance_name" {
  description = "Nombre de la instancia de Cloud SQL."
  type        = string
  default     = "chatwoot-db-prod"
}

variable "db_tier" {
  description = "Tier (tamaño) de la instancia de Cloud SQL."
  type        = string
  default     = "db-n1-standard-1"
}

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL."
  type        = string
  default     = "chatwoot_production"
}

variable "db_user" {
  description = "Nombre del usuario para la base de datos."
  type        = string
  default     = "chatwoot"
}

variable "db_password" {
  description = "Contraseña para el usuario de la base de datos. Si se deja en blanco, se generará una."
  type        = string
  default     = ""
  sensitive   = true
}