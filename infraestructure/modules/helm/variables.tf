variable "cluster_domain" {
  type = string
}

variable "acme_email" {
  type = string
}

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

variable "grafana_admin_password" {
  type = string
}

variable "cloudflare_tunnel_token" {
  type      = string
  sensitive = true
}

variable "vaultwarden_admin_token" {
  type      = string
  sensitive = true
}

variable "wireguard_admin_password_hash" {
  type      = string
  sensitive = true
}

variable "wireguard_public_host" {
  type    = string
  default = ""
}

variable "nexus_admin_password" {
  type      = string
  sensitive = true
}

variable "keycloak_admin_password" {
  type      = string
  sensitive = true
}

variable "keycloak_postgres_password" {
  type      = string
  sensitive = true
}

variable "keycloak_chart_archive_path" {
  type    = string
  default = null
}

variable "registry_htpasswd" {
  type      = string
  sensitive = true
}

variable "enable_wazuh" {
  type    = bool
  default = true
}

variable "headlamp_oauth_client_id" {
  type = string
}

variable "headlamp_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "headlamp_oauth_keycloak_realm" {
  type    = string
  default = "master"
}