variable "cluster_domain" {
  description = "Dominio base do cluster"
  type        = string
}

variable "admin_token" {
  description = "Token admin do Vaultwarden"
  type        = string
  sensitive   = true
}

variable "allow_signups" {
  description = "Permite cadastro publico no Vaultwarden"
  type        = bool
  default     = false
}
