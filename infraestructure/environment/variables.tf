variable "tenancy_id" {
  type = string
}

variable "user_id" {
  type = string
}

variable "api_fingerprint" {
  type = string
}

variable "api_private_key_path" {
  type = string
}

variable "region" {
  type = string
}

variable "oke_cluster_id" {
  type     = string
  default  = null
  nullable = true
}

variable "oke_kubernetes_endpoint" {
  type    = string
  default = "PUBLIC_ENDPOINT"
}

variable "terraform_state_bucket" {
  type = string
}

variable "terraform_state_region" {
  type = string
}

variable "terraform_state_namespace" {
  type        = string
  description = "Nome do namespace Object Storage (output de `oci os ns get` ou bucket endpoint)."
}

variable "terraform_state_cluster_key" {
  type    = string
  default = "infraestructure/cluster/terraform.tfstate"
}

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