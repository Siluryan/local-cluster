variable "bind_zone" {
  type = string
}

variable "bind_tsig_key_name" {
  type = string
}

variable "bind_tsig_secret" {
  type      = string
  sensitive = true
}

variable "bind_tsig_algorithm" {
  type    = string
  default = "hmac-sha256"
}
