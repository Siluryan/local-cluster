variable "cluster_domain" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "storage_size" {
  type    = string
  default = "10Gi"
}
