locals {
  bind_tsig_key_name_trigger = endswith(var.bind_tsig_key_name, ".") ? var.bind_tsig_key_name : "${var.bind_tsig_key_name}."
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.14.4"
  namespace        = "cert-manager"
  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]

  values = [
    yamlencode({
      prometheus = {
        enabled = false
      }
    })
  ]
}

resource "kubernetes_secret" "rfc2136_tsig_secret" {
  metadata {
    name      = "rfc2136-tsig-secret"
    namespace = "cert-manager"
  }

  data = {
    tsig-secret = var.bind_tsig_secret
  }

  type = "Opaque"

  depends_on = [helm_release.cert_manager]
}

resource "terraform_data" "wait_cert_manager_crds" {
  depends_on = [helm_release.cert_manager]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/certificates.cert-manager.io 2>/dev/null || true
      kubectl wait --for=condition=Established --timeout=180s crd/clusterissuers.cert-manager.io
    EOT
  }
}

resource "terraform_data" "apply_cluster_issuer_prod" {
  triggers_replace = [
    var.acme_email,
    var.bind_server,
    local.bind_tsig_key_name_trigger,
    var.bind_tsig_algorithm,
  ]

  depends_on = [
    kubernetes_secret.rfc2136_tsig_secret,
    terraform_data.wait_cert_manager_crds,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      cat <<'EOF' | kubectl apply -f -
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          email: ${var.acme_email}
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt-prod-account-key
          solvers:
            - dns01:
                rfc2136:
                  nameserver: ${var.bind_server}:53
                  tsigKeyName: ${local.bind_tsig_key_name_trigger}
                  tsigAlgorithm: ${upper(replace(var.bind_tsig_algorithm, "-", ""))}
                  tsigSecretSecretRef:
                    name: rfc2136-tsig-secret
                    key: tsig-secret
      EOF
    EOT
  }
}
