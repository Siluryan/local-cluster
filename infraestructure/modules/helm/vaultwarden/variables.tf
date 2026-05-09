variable "cluster_domain" {
  type = string
}

variable "admin_token" {
  type      = string
  sensitive = true
}

variable "allow_signups" {
  type    = bool
  default = false
}
