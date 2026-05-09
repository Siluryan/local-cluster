variable "cluster_domain" {
  type = string
}

variable "storage_size" {
  type    = string
  default = "10Gi"
}

variable "htpasswd" {
  type      = string
  sensitive = true
}
