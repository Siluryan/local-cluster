variable "cluster_domain" {
  description = "Dominio principal para filtro dos registros DNS"
  type        = string
}

variable "bind_server" {
  description = "Servidor DNS BIND para updates RFC2136"
  type        = string
}

variable "bind_zone" {
  description = "Zona DNS autoritativa"
  type        = string
}

variable "bind_tsig_key_name" {
  description = "Nome da chave TSIG"
  type        = string
}

variable "bind_tsig_secret" {
  description = "Segredo TSIG em base64"
  type        = string
  sensitive   = true
}

variable "bind_tsig_algorithm" {
  description = "Algoritmo TSIG para RFC2136"
  type        = string
  default     = "hmac-sha256"
}
