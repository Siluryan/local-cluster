variable "cluster_domain" {
  description = "Dominio base para hosts e registros DNS"
  type        = string
}

variable "acme_email" {
  description = "Email para cadastro no Let's Encrypt"
  type        = string
}

variable "bind_zone" {
  description = "Zona DNS gerenciada no BIND"
  type        = string
}

variable "bind_tsig_key_name" {
  description = "Nome da chave TSIG"
  type        = string
}

variable "bind_tsig_secret" {
  description = "Segredo TSIG em base64"
  type        = string
  sensitive   = true
}

variable "bind_tsig_algorithm" {
  description = "Algoritmo TSIG para RFC2136"
  type        = string
  default     = "hmac-sha256"
}

variable "grafana_admin_password" {
  description = "Senha do usuario admin do Grafana"
  type        = string
}

variable "cloudflare_tunnel_token" {
  description = "Token do Cloudflare Tunnel (remote-managed)"
  type        = string
  sensitive   = true
}

variable "vaultwarden_admin_token" {
  description = "Token admin do Vaultwarden"
  type        = string
  sensitive   = true
}

variable "wireguard_admin_password_hash" {
  description = "Hash bcrypt da senha do painel WG-Easy"
  type        = string
  sensitive   = true
}

variable "wireguard_public_host" {
  description = "Hostname publico para interface web do WireGuard"
  type        = string
  default     = ""
}

variable "nexus_admin_password" {
  description = "Senha admin do Nexus"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Senha do admin do Keycloak"
  type        = string
  sensitive   = true
}

variable "keycloak_postgres_password" {
  description = "Senha do Postgres do Keycloak"
  type        = string
  sensitive   = true
}

variable "registry_htpasswd" {
  description = "Conteudo do htpasswd do registry"
  type        = string
  sensitive   = true
}