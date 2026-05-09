module "helm" {
  source = "../modules/helm"

  cluster_domain                = var.cluster_domain
  acme_email                    = var.acme_email
  bind_zone                     = var.bind_zone
  bind_tsig_key_name            = var.bind_tsig_key_name
  bind_tsig_secret              = var.bind_tsig_secret
  bind_tsig_algorithm           = var.bind_tsig_algorithm
  grafana_admin_password        = var.grafana_admin_password
  cloudflare_tunnel_token       = var.cloudflare_tunnel_token
  vaultwarden_admin_token       = var.vaultwarden_admin_token
  wireguard_admin_password_hash = var.wireguard_admin_password_hash
  wireguard_public_host         = var.wireguard_public_host
  nexus_admin_password          = var.nexus_admin_password
  keycloak_admin_password       = var.keycloak_admin_password
  keycloak_postgres_password    = var.keycloak_postgres_password
  keycloak_chart_archive_path   = var.keycloak_chart_archive_path
  registry_htpasswd             = var.registry_htpasswd
  enable_wazuh                  = var.enable_wazuh
}