resource "helm_release" "wazuh" {
  name             = "wazuh"
  repository       = "https://packages.wazuh.com/4.x/helm/"
  chart            = "wazuh"
  version          = "0.1.2"
  namespace        = "wazuh"
  create_namespace = true

  values = [
    yamlencode({
      dashboard = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "wazuh_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "wazuh-dashboard"
      namespace = "wazuh"
    }
    spec = {
      parentRefs = [
        {
          name      = "envoy-gateway"
          namespace = "envoy-gateway-system"
        }
      ]
      hostnames = ["wazuh.${var.cluster_domain}"]
      rules = [
        {
          backendRefs = [
            {
              name = "wazuh-dashboard"
              port = 443
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.wazuh]
}

resource "kubernetes_manifest" "wazuh_dns" {
  manifest = {
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "wazuh-public"
      namespace = "wazuh"
    }
    spec = {
      endpoints = [
        {
          dnsName    = "wazuh.${var.cluster_domain}"
          recordTTL  = 60
          recordType = "CNAME"
          targets    = ["envoy-gateway.envoy-gateway-system"]
        }
      ]
    }
  }

  depends_on = [helm_release.wazuh]
}
