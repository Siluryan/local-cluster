resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.14.4"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

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

resource "kubernetes_manifest" "cluster_issuer_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [{
          dns01 = {
            rfc2136 = {
              nameserver    = "${var.bind_server}:53"
              tsigKeyName   = var.bind_tsig_key_name
              tsigAlgorithm = upper(replace(var.bind_tsig_algorithm, "-", ""))
              tsigSecretSecretRef = {
                name = "rfc2136-tsig-secret"
                key  = "tsig-secret"
              }
            }
          }
        }]
      }
    }
  }

  depends_on = [kubernetes_secret.rfc2136_tsig_secret]
}