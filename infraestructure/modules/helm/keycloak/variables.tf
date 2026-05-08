variable "cluster_domain" {
  description = "Dominio base do cluster"
  type        = string
}

variable "admin_password" {
  description = "Senha do admin do Keycloak"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Senha do Postgres do Keycloak"
  type        = string
  sensitive   = true
}
