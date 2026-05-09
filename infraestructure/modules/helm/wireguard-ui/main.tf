locals {
  wireguard_host = var.public_host != "" ? var.public_host : "vpn.${var.cluster_domain}"
}

resource "kubernetes_namespace" "wireguard" {
  metadata {
    name = "wireguard"
  }
}

resource "kubernetes_secret" "wireguard_env" {
  metadata {
    name      = "wireguard-env"
    namespace = kubernetes_namespace.wireguard.metadata[0].name
  }

  data = {
    PASSWORD_HASH = var.admin_password_hash
    WG_HOST       = local.wireguard_host
  }

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "wireguard_data" {
  wait_until_bound = false

  metadata {
    name      = "wireguard-data"
    namespace = kubernetes_namespace.wireguard.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "wireguard" {
  metadata {
    name      = "wg-easy"
    namespace = kubernetes_namespace.wireguard.metadata[0].name
    labels = {
      app = "wg-easy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wg-easy"
      }
    }

    template {
      metadata {
        labels = {
          app = "wg-easy"
        }
      }

      spec {
        container {
          name  = "wg-easy"
          image = "ghcr.io/wg-easy/wg-easy:14"

          security_context {
            capabilities {
              add = ["NET_ADMIN", "SYS_MODULE"]
            }
          }

          port {
            container_port = 51820
            name           = "wireguard-udp"
            protocol       = "UDP"
          }

          port {
            container_port = 51821
            name           = "web"
            protocol       = "TCP"
          }

          env {
            name  = "LANG"
            value = "pt_BR"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.wireguard_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "wireguard-data"
            mount_path = "/etc/wireguard"
          }
        }

        volume {
          name = "wireguard-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wireguard_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wireguard_vpn" {
  metadata {
    name      = "wireguard-vpn"
    namespace = kubernetes_namespace.wireguard.metadata[0].name
  }

  spec {
    selector = {
      app = "wg-easy"
    }

    port {
      name        = "wireguard-udp"
      port        = 51820
      target_port = 51820
      protocol    = "UDP"
    }

    type = var.service_type
  }
}

resource "kubernetes_service" "wireguard_ui" {
  metadata {
    name      = "wireguard-ui"
    namespace = kubernetes_namespace.wireguard.metadata[0].name
  }

  spec {
    selector = {
      app = "wg-easy"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 51821
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "terraform_data" "wireguard_route_dns" {
  triggers_replace = [local.wireguard_host]

  depends_on = [kubernetes_service.wireguard_ui]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: wireguard-ui
        namespace: ${kubernetes_namespace.wireguard.metadata[0].name}
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - ${local.wireguard_host}
        rules:
          - backendRefs:
              - name: ${kubernetes_service.wireguard_ui.metadata[0].name}
                port: 80
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: wireguard-ui-public
        namespace: ${kubernetes_namespace.wireguard.metadata[0].name}
      spec:
        endpoints:
          - dnsName: ${local.wireguard_host}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
