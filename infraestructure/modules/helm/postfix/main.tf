resource "kubernetes_namespace" "mail" {
  metadata {
    name = "mail"
  }
}

locals {
  relay_env = trimspace(var.relayhost) != "" ? merge(
    {
      RELAYHOST = trimspace(var.relayhost)
    },
    trimspace(var.relayhost_username) != "" ? {
      RELAYHOST_USERNAME = var.relayhost_username
      RELAYHOST_PASSWORD = var.relayhost_password
    } : {}
  ) : {}
  postfix_env = merge({
    ALLOWED_SENDER_DOMAINS = var.allowed_sender_domains
    SMTPD_SASL_USERS       = var.smtpd_sasl_users
    POSTFIX_myhostname     = "postfix.mail.svc.cluster.local"
  }, local.relay_env)
}

resource "kubernetes_secret" "postfix_env" {
  metadata {
    name      = "postfix-env"
    namespace = kubernetes_namespace.mail.metadata[0].name
  }

  data = local.postfix_env

  type = "Opaque"
}

resource "kubernetes_deployment" "postfix" {
  metadata {
    name      = "postfix"
    namespace = kubernetes_namespace.mail.metadata[0].name
    labels = {
      app = "postfix"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postfix"
      }
    }

    template {
      metadata {
        labels = {
          app = "postfix"
        }
      }

      spec {
        container {
          name  = "postfix"
          image = var.postfix_image

          port {
            container_port = 587
            name           = "submission"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postfix_env.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              memory = "512Mi"
            }
          }

          readiness_probe {
            tcp_socket {
              port = 587
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          liveness_probe {
            tcp_socket {
              port = 587
            }
            initial_delay_seconds = 45
            period_seconds        = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postfix" {
  metadata {
    name      = "postfix"
    namespace = kubernetes_namespace.mail.metadata[0].name
  }

  spec {
    selector = {
      app = "postfix"
    }

    port {
      name        = "submission"
      port        = 587
      target_port = "submission"
    }

    type = "ClusterIP"
  }
}
