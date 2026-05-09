variable "cluster_domain" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "chart_archive_path" {
  type    = string
  default = null
}
