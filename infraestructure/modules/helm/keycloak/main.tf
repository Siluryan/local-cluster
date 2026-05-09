resource "helm_release" "keycloak" {
  name             = "keycloak"
  repository       = var.chart_archive_path != null ? null : "https://charts.bitnami.com/bitnami"
  chart            = coalesce(var.chart_archive_path, "keycloak")
  version          = var.chart_archive_path != null ? null : "24.7.4"
  namespace        = "keycloak"
  create_namespace = true

  values = [
    yamlencode({
      global = {
        security = {
          allowInsecureImages = true
        }
      }
      auth = {
        adminUser     = "admin"
        adminPassword = var.admin_password
      }
      image = {
        registry   = "docker.io"
        repository = "bitnamilegacy/keycloak"
        tag        = "26.2.5-debian-12-r3"
      }
      production = false
      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
        limits = {
          cpu    = "1500m"
          memory = "2Gi"
        }
      }
      proxy = "edge"
      cache = {
        enabled = false
      }
      ingress = {
        enabled = false
      }
      postgresql = {
        enabled = true
        image = {
          registry   = "docker.io"
          repository = "bitnamilegacy/postgresql"
          tag        = "17.6.0-debian-12-r4"
        }
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
        },
        {
          name  = "KC_HTTP_ENABLED"
          value = "true"
        },
        {
          name  = "KC_CACHE"
          value = "local"
        }
      ]
    })
  ]
}

resource "terraform_data" "keycloak_route_dns" {
  triggers_replace = [var.cluster_domain]

  depends_on = [helm_release.keycloak]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: keycloak
        namespace: keycloak
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - keycloak.${var.cluster_domain}
        rules:
          - backendRefs:
              - name: keycloak
                port: 80
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: keycloak-public
        namespace: keycloak
      spec:
        endpoints:
          - dnsName: keycloak.${var.cluster_domain}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
