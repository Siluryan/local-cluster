resource "kubernetes_namespace" "vaultwarden" {
  metadata {
    name = "vaultwarden"
  }
}

resource "kubernetes_secret" "vaultwarden_env" {
  metadata {
    name      = "vaultwarden-env"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = {
    ADMIN_TOKEN     = var.admin_token
    SIGNUPS_ALLOWED = var.allow_signups ? "true" : "false"
  }

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "vaultwarden_data" {
  metadata {
    name      = "vaultwarden-data"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "vaultwarden" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    labels = {
      app = "vaultwarden"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vaultwarden"
      }
    }

    template {
      metadata {
        labels = {
          app = "vaultwarden"
        }
      }

      spec {
        container {
          name  = "vaultwarden"
          image = "vaultwarden/server:1.33.2"

          port {
            container_port = 80
            name           = "http"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.vaultwarden_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "vaultwarden-data"
            mount_path = "/data"
          }
        }

        volume {
          name = "vaultwarden-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.vaultwarden_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vaultwarden" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "vaultwarden_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "vaultwarden"
      namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name      = "envoy-gateway"
          namespace = "envoy-gateway-system"
        }
      ]
      hostnames = ["vaultwarden.${var.cluster_domain}"]
      rules = [
        {
          backendRefs = [
            {
              name = kubernetes_service.vaultwarden.metadata[0].name
              port = 80
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "vaultwarden_dns" {
  manifest = {
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "vaultwarden-public"
      namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    }
    spec = {
      endpoints = [
        {
          dnsName    = "vaultwarden.${var.cluster_domain}"
          recordTTL  = 60
          recordType = "CNAME"
          targets    = ["envoy-gateway.envoy-gateway-system"]
        }
      ]
    }
  }
}
