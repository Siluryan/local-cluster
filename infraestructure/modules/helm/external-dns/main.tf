locals {
  tsig_keyname_rfc2136 = endswith(var.bind_tsig_key_name, ".") ? var.bind_tsig_key_name : "${var.bind_tsig_key_name}."
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.15.0"
  namespace        = "external-dns"
  create_namespace = true

  values = [
    yamlencode({
      crd = {
        create = true
      }
      domainFilters = [var.cluster_domain]
      extraArgs = [
        "--rfc2136-host=${var.bind_server}",
        "--rfc2136-port=53",
        "--rfc2136-zone=${var.bind_zone}",
        "--rfc2136-min-ttl=60s",
        "--rfc2136-tsig-secret=${var.bind_tsig_secret}",
        "--rfc2136-tsig-secret-alg=${var.bind_tsig_algorithm}",
        "--rfc2136-tsig-keyname=${local.tsig_keyname_rfc2136}",
      ]
      policy = "sync"
      provider = {
        name = "rfc2136"
      }
      registry   = "txt"
      sources    = ["service", "ingress", "gateway-httproute", "crd"]
      txtOwnerId = "local-cluster"
    })
  ]
}
