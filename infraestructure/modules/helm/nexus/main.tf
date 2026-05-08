resource "helm_release" "nexus" {
  name             = "nexus"
  repository       = "https://sonatype.github.io/helm3-charts/"
  chart            = "nexus-repository-manager"
  version          = "64.2.0"
  namespace        = "nexus"
  create_namespace = true

  values = [
    yamlencode({
      nexus = {
        docker = {
          enabled = false
        }
      }
      persistence = {
        enabled     = true
        storageSize = var.storage_size
      }
      service = {
        type = "ClusterIP"
      }
      env = [
        {
          name  = "NEXUS_SECURITY_RANDOMPASSWORD"
          value = "false"
        }
      ]
      secret = {
        enabled = true
        data = {
          "nexus-admin-password" = var.admin_password
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "nexus_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "nexus"
      namespace = "nexus"
    }
    spec = {
      parentRefs = [
        {
          name      = "envoy-gateway"
          namespace = "envoy-gateway-system"
        }
      ]
      hostnames = ["nexus.${var.cluster_domain}"]
      rules = [
        {
          backendRefs = [
            {
              name = "nexus-nexus-repository-manager"
              port = 8081
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.nexus]
}

resource "kubernetes_manifest" "nexus_dns" {
  manifest = {
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "nexus-public"
      namespace = "nexus"
    }
    spec = {
      endpoints = [
        {
          dnsName    = "nexus.${var.cluster_domain}"
          recordTTL  = 60
          recordType = "CNAME"
          targets    = ["envoy-gateway.envoy-gateway-system"]
        }
      ]
    }
  }

  depends_on = [helm_release.nexus]
}
