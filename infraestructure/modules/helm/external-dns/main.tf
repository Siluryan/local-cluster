resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.15.0"
  namespace        = "external-dns"
  create_namespace = true

  values = [
    yamlencode({
      provider = {
        name = "rfc2136"
      }
      policy        = "sync"
      registry      = "txt"
      txtOwnerId    = "local-cluster"
      domainFilters = [var.cluster_domain]
      sources       = ["service", "ingress", "gateway-httproute", "crd"]
      rfc2136 = {
        host          = var.bind_server
        port          = 53
        zone          = "${var.bind_zone}."
        tsigKeyname   = var.bind_tsig_key_name
        tsigSecret    = var.bind_tsig_secret
        tsigSecretAlg = var.bind_tsig_algorithm
        minTTL        = 60
      }
      crd = {
        create = true
      }
    })
  ]
}
