variable "cluster_domain" {
  type = string
}

variable "admin_password_hash" {
  type      = string
  sensitive = true
}

variable "public_host" {
  type    = string
  default = ""
}

variable "service_type" {
  type    = string
  default = "NodePort"
}
