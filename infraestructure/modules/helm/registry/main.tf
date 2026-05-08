locals {
  registry_host = "registry.${var.cluster_domain}"
}

resource "kubernetes_namespace" "registry" {
  metadata {
    name = "registry"
  }
}

resource "kubernetes_secret" "htpasswd" {
  metadata {
    name      = "registry-htpasswd"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  data = {
    htpasswd = var.htpasswd
  }

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "registry" {
  metadata {
    name      = "registry-data"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

resource "kubernetes_deployment" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
    labels = {
      app = "registry"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "registry"
      }
    }

    template {
      metadata {
        labels = {
          app = "registry"
        }
      }

      spec {
        container {
          name  = "registry"
          image = "registry:2"

          port {
            name           = "http"
            container_port = 5000
            protocol       = "TCP"
          }

          env {
            name  = "REGISTRY_HTTP_ADDR"
            value = "0.0.0.0:5000"
          }

          env {
            name  = "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY"
            value = "/var/lib/registry"
          }

          env {
            name  = "REGISTRY_AUTH"
            value = "htpasswd"
          }

          env {
            name  = "REGISTRY_AUTH_HTPASSWD_REALM"
            value = "Registry Realm"
          }

          env {
            name  = "REGISTRY_AUTH_HTPASSWD_PATH"
            value = "/auth/htpasswd"
          }

          volume_mount {
            name       = "registry-data"
            mount_path = "/var/lib/registry"
          }

          volume_mount {
            name       = "auth"
            mount_path = "/auth"
            read_only  = true
          }
        }

        volume {
          name = "registry-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.registry.metadata[0].name
          }
        }

        volume {
          name = "auth"
          secret {
            secret_name = kubernetes_secret.htpasswd.metadata[0].name
            items {
              key  = "htpasswd"
              path = "htpasswd"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  spec {
    selector = {
      app = "registry"
    }

    port {
      name        = "http"
      port        = 5000
      target_port = 5000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "registry_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "registry"
      namespace = kubernetes_namespace.registry.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name      = "envoy-gateway"
          namespace = "envoy-gateway-system"
        }
      ]
      hostnames = [local.registry_host]
      rules = [
        {
          backendRefs = [
            {
              name = kubernetes_service.registry.metadata[0].name
              port = 5000
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "registry_dns" {
  manifest = {
    apiVersion = "externaldns.k8s.io/v1alpha1"
    kind       = "DNSEndpoint"
    metadata = {
      name      = "registry-public"
      namespace = kubernetes_namespace.registry.metadata[0].name
    }
    spec = {
      endpoints = [
        {
          dnsName    = local.registry_host
          recordTTL  = 60
          recordType = "CNAME"
          targets    = ["envoy-gateway.envoy-gateway-system"]
        }
      ]
    }
  }
}

