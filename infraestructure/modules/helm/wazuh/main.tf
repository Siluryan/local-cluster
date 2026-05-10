resource "helm_release" "wazuh" {
  name             = "wazuh"
  repository       = "https://morgoved.github.io/wazuh-helm/"
  chart            = "wazuh"
  version          = "1.0.23"
  namespace        = "wazuh"
  create_namespace = true

  values = [
    yamlencode({
      "cert-manager" = {
        enabled = false
      }
      indexer = {
        replicas = 1
        networkPolicy = {
          enabled = false
        }
      }
      dashboard = {
        service = {
          type = "ClusterIP"
        }
        networkPolicy = {
          enabled = false
        }
      }
      wazuh = {
        master = {
          networkPolicy = {
            enabled = false
          }
        }
        worker = {
          replicas = 1
          networkPolicy = {
            enabled = false
          }
        }
      }
    })
  ]
}

resource "terraform_data" "wazuh_route_dns" {
  triggers_replace = [var.cluster_domain]

  depends_on = [helm_release.wazuh]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: wazuh-dashboard
        namespace: wazuh
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - wazuh.${var.cluster_domain}
        rules:
          - backendRefs:
              - name: wazuh-dashboard
                port: 5601
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: wazuh-public
        namespace: wazuh
      spec:
        endpoints:
          - dnsName: wazuh.${var.cluster_domain}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
