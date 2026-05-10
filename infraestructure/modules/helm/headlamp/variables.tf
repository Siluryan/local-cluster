variable "cluster_domain" {
  type = string
}

variable "oauth_client_id" {
  type = string
}

variable "oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "oauth_keycloak_realm" {
  type    = string
  default = "master"
}
