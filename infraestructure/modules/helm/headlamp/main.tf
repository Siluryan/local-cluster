resource "helm_release" "headlamp" {
  name             = "headlamp"
  repository       = "https://kubernetes-sigs.github.io/headlamp/"
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

resource "terraform_data" "headlamp_route_dns" {
  triggers_replace = [var.cluster_domain]

  depends_on = [helm_release.headlamp]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: headlamp
        namespace: headlamp
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - headlamp.${var.cluster_domain}
        rules:
          - backendRefs:
              - name: headlamp
                port: 80
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: headlamp-public
        namespace: headlamp
      spec:
        endpoints:
          - dnsName: headlamp.${var.cluster_domain}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
