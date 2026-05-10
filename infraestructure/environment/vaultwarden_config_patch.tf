resource "null_resource" "vaultwarden_config_smtp_accept_insecure" {
  count = var.vaultwarden_config_patch_invalid_certs ? 1 : 0

  triggers = {
    vaultwarden_secret_version = module.helm.vaultwarden_env_secret_resource_version
    patch_run_id               = var.vaultwarden_config_patch_run_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      export KUBECONFIG="${pathexpand(var.kubeconfig_path)}"
      K="${var.kube_context != "" ? format("--context=%s ", var.kube_context) : ""}"
      kubectl $K rollout status deployment/vaultwarden -n vaultwarden --timeout=180s
      kubectl $K exec -n vaultwarden deploy/vaultwarden -- sh -ec '
        test -f /data/config.json || exit 0
        sed -i "s/\"smtp_accept_invalid_certs\": false/\"smtp_accept_invalid_certs\": true/g" /data/config.json
        sed -i "s/\"smtp_accept_invalid_hostnames\": false/\"smtp_accept_invalid_hostnames\": true/g" /data/config.json
      '
      kubectl $K rollout restart deployment/vaultwarden -n vaultwarden
      kubectl $K rollout status deployment/vaultwarden -n vaultwarden --timeout=180s
    EOT
  }

  depends_on = [module.helm]
}
