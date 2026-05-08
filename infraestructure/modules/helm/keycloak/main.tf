resource "helm_release" "keycloak" {
  name             = "keycloak"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "keycloak"
  version          = "24.7.4"
  namespace        = "keycloak"
  create_namespace = true

  values = [
    yamlencode({
      auth = {
        adminUser     = "admin"
        adminPassword = var.admin_password
      }
      production = true
      proxy      = "edge"
      ingress = {
        enabled = false
      }
      postgresql = {
        enabled = true
        auth = {
          username = "bn_keycloak"
          password = var.postgres_password
          database = "bitnami_keycloak"
        }
      }
      service = {
        type = "ClusterIP"
        ports = {
          http = 80
        }
      }
      extraEnvVars = [
        {
          name  = "KC_HOSTNAME"
          value = "keycloak.${var.cluster_domain}"
        },
        {
          name  = "KC_PROXY_HEADERS"
          value = "xforwarded"
        }
      ]
    })
  ]
}

resource "kubernetes_manifest" "keycloak_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "keycloak"
      namespace = "keycloak"
    }
    spec = {
      parentRefs = [
        {
          name      = "envoy-gateway"
          namespace = "envoy-gateway-system"
        }
      ]
      hostnames = ["keycloak.${var.cluster_domain}"]
      rules = [
        {
          backendRefs = [
            {
              name = "keycloak"
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.keycloak]
}

resource "kubernetes_manifest" "keycloak_dns" {
  manifest = {
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "keycloak-public"
      namespace = "keycloak"
    }
    spec = {
      endpoints = [
        {
          dnsName    = "keycloak.${var.cluster_domain}"
          recordTTL  = 60
          recordType = "CNAME"
          targets    = ["envoy-gateway.envoy-gateway-system"]
        }
      ]
    }
  }

  depends_on = [helm_release.keycloak]
}
