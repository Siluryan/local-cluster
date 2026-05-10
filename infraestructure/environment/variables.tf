variable "kubeconfig_path" {
  type = string
  validation {
    condition     = length(trimspace(var.kubeconfig_path)) > 0
    error_message = "kubeconfig_path must be non-empty."
  }
}

variable "kube_context" {
  type    = string
  default = ""
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

variable "postfix_enabled" {
  type    = bool
  default = false
}

variable "postfix_extra_allowed_sender_domains" {
  type    = string
  default = ""
}

variable "postfix_relayhost" {
  type    = string
  default = ""

  validation {
    condition     = trimspace(var.postfix_relayhost) == "" || trimspace(var.postfix_relay_username) == "" || length(trimspace(var.postfix_relay_password)) > 0
    error_message = "postfix_relay_password is required when postfix_relayhost and postfix_relay_username are set."
  }
}

variable "postfix_relay_username" {
  type    = string
  default = ""
}

variable "postfix_relay_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "vaultwarden_smtp_host" {
  type    = string
  default = ""
}

variable "vaultwarden_smtp_port" {
  type    = string
  default = "587"

  validation {
    condition     = can(tonumber(var.vaultwarden_smtp_port)) && tonumber(var.vaultwarden_smtp_port) >= 1 && tonumber(var.vaultwarden_smtp_port) <= 65535
    error_message = "vaultwarden_smtp_port must be between 1 and 65535."
  }
}

variable "vaultwarden_smtp_security" {
  type    = string
  default = "starttls"

  validation {
    condition     = contains(["starttls", "force_tls", "off"], var.vaultwarden_smtp_security)
    error_message = "vaultwarden_smtp_security must be starttls, force_tls, or off."
  }
}

variable "vaultwarden_smtp_username" {
  type    = string
  default = ""

  validation {
    condition = (
      (trimspace(var.vaultwarden_smtp_username) == "" || length(trimspace(var.vaultwarden_smtp_password)) > 0) &&
      (!var.postfix_enabled || length(trimspace(var.vaultwarden_smtp_username)) > 0)
    )
    error_message = "When postfix_enabled, set vaultwarden_smtp_username and vaultwarden_smtp_password. If username is set, password is required."
  }
}

variable "vaultwarden_smtp_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "vaultwarden_smtp_from" {
  type    = string
  default = ""

  validation {
    condition = (
      (trimspace(var.vaultwarden_smtp_host) == "" && !var.postfix_enabled) ||
      length(trimspace(var.vaultwarden_smtp_from)) > 0
    )
    error_message = "vaultwarden_smtp_from is required when vaultwarden_smtp_host is set or postfix_enabled is true."
  }
}

variable "vaultwarden_smtp_from_name" {
  type    = string
  default = "Vaultwarden"
}

variable "vaultwarden_smtp_accept_invalid_certs" {
  type    = bool
  default = false
}

variable "vaultwarden_config_patch_invalid_certs" {
  type    = bool
  default = true
}

variable "vaultwarden_config_patch_run_id" {
  type    = string
  default = "1"
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
