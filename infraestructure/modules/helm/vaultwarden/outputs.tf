output "env_secret_resource_version" {
  value = kubernetes_secret.vaultwarden_env.metadata[0].resource_version
}
