resource "helm_release" "headlamp" {
  name             = "headlamp"
  repository       = "https://headlamp-k8s.github.io/headlamp/"
  chart            = "headlamp"
  version          = "0.27.0"
  namespace        = "headlamp"
  create_namespace = true

  values = [
    yamlencode({
      service = {
        type = "ClusterIP"
        port = 80
      }
    })
  ]
}

resource "kubernetes_manifest" "headlamp_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "headlamp"
      namespace = "headlamp"
    }
    spec = {
      parentRefs = [
        {
          name      = "envoy-gateway"
          namespace = "envoy-gateway-system"
        }
      ]
      hostnames = ["headlamp.${var.cluster_domain}"]
      rules = [
        {
          backendRefs = [
            {
              name = "headlamp"
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.headlamp]
}

resource "kubernetes_manifest" "headlamp_dns" {
  manifest = {
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "headlamp-public"
      namespace = "headlamp"
    }
    spec = {
      endpoints = [
        {
          dnsName    = "headlamp.${var.cluster_domain}"
          recordTTL  = 60
          recordType = "CNAME"
          targets    = ["envoy-gateway.envoy-gateway-system"]
        }
      ]
    }
  }

  depends_on = [helm_release.headlamp]
}
