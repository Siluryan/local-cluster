variable "cluster_domain" {
  description = "Dominio base do cluster"
  type        = string
}

variable "storage_size" {
  description = "Tamanho do PVC do registry"
  type        = string
  default     = "10Gi"
}

variable "htpasswd" {
  description = "Conteudo do htpasswd (linha usuario:hash) para Basic Auth"
  type        = string
  sensitive   = true
}
