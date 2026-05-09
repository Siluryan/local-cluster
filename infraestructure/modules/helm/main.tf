locals {
  keycloak_chart_cache = abspath("${path.module}/../../../.helm/cache/repository/keycloak-24.7.4.tgz")
  keycloak_chart_auto  = fileexists(local.keycloak_chart_cache) ? local.keycloak_chart_cache : null
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

module "vaultwarden" {
  source = "./vaultwarden"

  cluster_domain = var.cluster_domain
  admin_token    = var.vaultwarden_admin_token
  depends_on     = [module.envoy, module.external_secrets]
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

  cluster_domain = var.cluster_domain
  depends_on     = [module.envoy, module.external_dns]
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