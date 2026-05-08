variable "acme_email" {
  description = "Email usado para registro no Let's Encrypt"
  type        = string
}

variable "bind_server" {
  description = "Servidor BIND autoritativo para DNS01"
  type        = string
}

variable "bind_tsig_key_name" {
  description = "Nome da chave TSIG do BIND"
  type        = string
}

variable "bind_tsig_secret" {
  description = "Segredo TSIG em base64 para RFC2136"
  type        = string
  sensitive   = true
}

variable "bind_tsig_algorithm" {
  description = "Algoritmo TSIG (hmac-sha256, hmac-sha512, etc.)"
  type        = string
  default     = "hmac-sha256"
}
