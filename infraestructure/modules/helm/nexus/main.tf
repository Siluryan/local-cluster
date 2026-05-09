resource "kubernetes_namespace" "nexus" {
  metadata {
    name = "nexus"
  }
}

resource "kubernetes_secret" "nexus_repository_manager_secret" {
  metadata {
    name      = "nexus-repository-manager-secret"
    namespace = kubernetes_namespace.nexus.metadata[0].name
  }

  data = {
    "nexus-admin-password" = var.admin_password
  }

  type = "Opaque"
}

resource "helm_release" "nexus" {
  name             = "nexus"
  repository       = "https://sonatype.github.io/helm3-charts/"
  chart            = "nexus-repository-manager"
  version          = "64.2.0"
  namespace        = kubernetes_namespace.nexus.metadata[0].name
  create_namespace = false

  depends_on = [kubernetes_secret.nexus_repository_manager_secret]

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
        enabled = false
      }
    })
  ]
}

resource "terraform_data" "nexus_route_dns" {
  triggers_replace = [var.cluster_domain]

  depends_on = [helm_release.nexus]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: nexus
        namespace: nexus
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - nexus.${var.cluster_domain}
        rules:
          - backendRefs:
              - name: nexus-nexus-repository-manager
                port: 8081
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: nexus-public
        namespace: nexus
      spec:
        endpoints:
          - dnsName: nexus.${var.cluster_domain}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
