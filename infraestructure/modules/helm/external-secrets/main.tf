resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.10.5"
  namespace        = "external-secrets"
  create_namespace = true

  values = [
    yamlencode({
      installCRDs  = true
      replicaCount = 1
      webhook = {
        replicaCount = 1
      }
      certController = {
        replicaCount = 1
      }
    })
  ]
}
