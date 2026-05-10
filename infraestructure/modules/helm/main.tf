locals {
  keycloak_chart_cache = abspath("${path.module}/../../../.helm/cache/repository/keycloak-24.7.4.tgz")
  keycloak_chart_auto  = fileexists(local.keycloak_chart_cache) ? local.keycloak_chart_cache : null

  vaultwarden_from_domain = length(split("@", trimspace(var.vaultwarden_smtp_from))) >= 2 ? trimspace(element(split("@", trimspace(var.vaultwarden_smtp_from)), 1)) : ""
  postfix_allowed_domains = join(" ", compact(distinct(concat(
    local.vaultwarden_from_domain != "" ? [local.vaultwarden_from_domain] : [],
    compact(split(" ", trimspace(var.postfix_extra_allowed_sender_domains)))
  ))))

  vaultwarden_smtp_host_resolved = var.postfix_enabled ? module.postfix[0].submission_host : var.vaultwarden_smtp_host

  vaultwarden_smtp_accept_invalid_certs_effective = var.postfix_enabled || var.vaultwarden_smtp_accept_invalid_certs
}

module "bind" {
  source = "./bind"

  bind_zone           = var.bind_zone
  bind_tsig_key_name  = var.bind_tsig_key_name
  bind_tsig_secret    = var.bind_tsig_secret
  bind_tsig_algorithm = var.bind_tsig_algorithm
}

module "cert_manager" {
  source = "./cert-manager"

  acme_email          = var.acme_email
  bind_server         = module.bind.bind_service
  bind_tsig_key_name  = var.bind_tsig_key_name
  bind_tsig_secret    = var.bind_tsig_secret
  bind_tsig_algorithm = var.bind_tsig_algorithm
  depends_on          = [module.bind]
}

module "envoy" {
  source = "./envoy"
}

module "external_dns" {
  source = "./external-dns"

  cluster_domain      = var.cluster_domain
  bind_server         = module.bind.bind_service
  bind_zone           = var.bind_zone
  bind_tsig_key_name  = var.bind_tsig_key_name
  bind_tsig_secret    = var.bind_tsig_secret
  bind_tsig_algorithm = var.bind_tsig_algorithm
  depends_on          = [module.cert_manager, module.bind]
}

module "monitoring" {
  source = "./monitoring"

  cluster_domain         = var.cluster_domain
  grafana_admin_password = var.grafana_admin_password
  depends_on             = [module.envoy, module.cert_manager]
}

module "glowroot" {
  source = "./glowroot"

  depends_on = [module.envoy]
}

module "cloudflare_tunnel" {
  source = "./cloudflare-tunnel"

  cloudflare_tunnel_token = var.cloudflare_tunnel_token
  depends_on              = [module.envoy]
}

module "external_secrets" {
  source = "./external-secrets"

  depends_on = [module.envoy]
}

check "postfix_mail_ready" {
  assert {
    condition     = !var.postfix_enabled || length(trimspace(local.postfix_allowed_domains)) > 0
    error_message = "With postfix_enabled, set vaultwarden_smtp_from (address with @domain) and/or postfix_extra_allowed_sender_domains."
  }

  assert {
    condition     = !var.postfix_enabled || length(trimspace(var.vaultwarden_smtp_username)) > 0
    error_message = "With postfix_enabled, set vaultwarden_smtp_username."
  }

  assert {
    condition     = !var.postfix_enabled || length(trimspace(var.vaultwarden_smtp_password)) > 0
    error_message = "With postfix_enabled, set vaultwarden_smtp_password."
  }
}

module "postfix" {
  count  = var.postfix_enabled ? 1 : 0
  source = "./postfix"

  allowed_sender_domains = local.postfix_allowed_domains
  smtpd_sasl_users       = "${trimspace(var.vaultwarden_smtp_username)}:${var.vaultwarden_smtp_password}"
  relayhost              = var.postfix_relayhost
  relayhost_username     = var.postfix_relay_username
  relayhost_password     = var.postfix_relay_password

  depends_on = [module.envoy]
}

module "vaultwarden" {
  source = "./vaultwarden"

  cluster_domain            = var.cluster_domain
  admin_token               = var.vaultwarden_admin_token
  smtp_host                 = local.vaultwarden_smtp_host_resolved
  smtp_port                 = var.vaultwarden_smtp_port
  smtp_security             = var.vaultwarden_smtp_security
  smtp_username             = var.vaultwarden_smtp_username
  smtp_password             = var.vaultwarden_smtp_password
  smtp_from                 = var.vaultwarden_smtp_from
  smtp_from_name            = var.vaultwarden_smtp_from_name
  smtp_accept_invalid_certs = local.vaultwarden_smtp_accept_invalid_certs_effective
  depends_on                = [module.envoy, module.external_secrets]
}

module "wireguard_ui" {
  source = "./wireguard-ui"

  cluster_domain      = var.cluster_domain
  admin_password_hash = var.wireguard_admin_password_hash
  public_host         = var.wireguard_public_host
  depends_on          = [module.envoy, module.external_dns]
}

module "headlamp" {
  source = "./headlamp"

  cluster_domain       = var.cluster_domain
  oauth_client_id      = var.headlamp_oauth_client_id
  oauth_client_secret  = var.headlamp_oauth_client_secret
  oauth_keycloak_realm = var.headlamp_oauth_keycloak_realm
  depends_on           = [module.envoy, module.external_dns, module.keycloak]
}

module "nexus" {
  source = "./nexus"

  cluster_domain = var.cluster_domain
  admin_password = var.nexus_admin_password
  depends_on     = [module.envoy, module.external_dns]
}

module "keycloak" {
  source = "./keycloak"

  cluster_domain     = var.cluster_domain
  admin_password     = var.keycloak_admin_password
  postgres_password  = var.keycloak_postgres_password
  chart_archive_path = var.keycloak_chart_archive_path != null ? var.keycloak_chart_archive_path : local.keycloak_chart_auto
  depends_on         = [module.envoy, module.external_dns]
}

module "registry" {
  source = "./registry"

  cluster_domain = var.cluster_domain
  htpasswd       = var.registry_htpasswd
  depends_on     = [module.envoy, module.external_dns]
}

module "wazuh" {
  count  = var.enable_wazuh ? 1 : 0
  source = "./wazuh"

  cluster_domain = var.cluster_domain
  depends_on     = [module.envoy, module.external_dns]
}