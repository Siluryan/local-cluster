variable "cluster_domain" {
  description = "Dominio base do cluster"
  type        = string
}

variable "admin_password" {
  description = "Senha admin do Nexus"
  type        = string
  sensitive   = true
}

variable "storage_size" {
  description = "Tamanho do PVC do Nexus"
  type        = string
  default     = "10Gi"
}
