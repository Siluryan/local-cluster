resource "kubernetes_namespace" "glowroot" {
  metadata {
    name = "glowroot"
  }
}

resource "kubernetes_deployment" "glowroot" {
  metadata {
    name      = "glowroot-central"
    namespace = kubernetes_namespace.glowroot.metadata[0].name
    labels = {
      app = "glowroot-central"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "glowroot-central"
      }
    }

    template {
      metadata {
        labels = {
          app = "glowroot-central"
        }
      }

      spec {
        container {
          name  = "glowroot"
          image = "glowroot/glowroot-central:0.14.3"

          port {
            container_port = 4000
            name           = "http"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "glowroot" {
  metadata {
    name      = "glowroot-central"
    namespace = kubernetes_namespace.glowroot.metadata[0].name
  }

  spec {
    selector = {
      app = "glowroot-central"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 4000
    }

    type = "ClusterIP"
  }
}
