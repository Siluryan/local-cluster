variable "bind_zone" {
  description = "Zona autoritativa do BIND"
  type        = string
}

variable "bind_tsig_key_name" {
  description = "Nome da chave TSIG usada para update dinamico"
  type        = string
}

variable "bind_tsig_secret" {
  description = "Segredo TSIG em base64"
  type        = string
  sensitive   = true
}

variable "bind_tsig_algorithm" {
  description = "Algoritmo TSIG"
  type        = string
  default     = "hmac-sha256"
}
