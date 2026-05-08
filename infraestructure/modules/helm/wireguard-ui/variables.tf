variable "cluster_domain" {
  description = "Dominio base do cluster"
  type        = string
}

variable "admin_password_hash" {
  description = "Hash bcrypt da senha admin do WG-Easy"
  type        = string
  sensitive   = true
}

variable "public_host" {
  description = "Hostname publico da interface do WireGuard"
  type        = string
  default     = ""
}

variable "service_type" {
  description = "Tipo do Service UDP do WireGuard"
  type        = string
  default     = "NodePort"
}
