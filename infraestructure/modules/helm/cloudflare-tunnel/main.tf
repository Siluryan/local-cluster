resource "kubernetes_namespace" "cloudflare_tunnel" {
  metadata {
    name = "cloudflare-tunnel"
  }
}

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = kubernetes_namespace.cloudflare_tunnel.metadata[0].name
    labels = {
      app = "cloudflared"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cloudflared"
      }
    }

    template {
      metadata {
        labels = {
          app = "cloudflared"
        }
      }

      spec {
        container {
          name  = "cloudflared"
          image = "cloudflare/cloudflared:2026.4.0"

          args = [
            "tunnel",
            "--no-autoupdate",
            "run"
          ]

          env {
            name  = "TUNNEL_TOKEN"
            value = var.cloudflare_tunnel_token
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
